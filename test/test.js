const Sale = artifacts.require("Sale");
const MKToken = artifacts.require("MKToken");

const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { web3 } = require("hardhat");
const BN = require('bn.js');

const ether = (val) => web3.utils.toWei(val.toString(), "ether");

contract("Sale", (accounts) => {
    const [owner, user1, user2] = accounts;
    const ethPerToken = ether("0.01"); // 1 token = 0.01 ETH
    const claimDuration = time.duration.days(7); // 1 week

    let token, sale;

    beforeEach(async () => {
        token = await MKToken.new();
        sale = await Sale.new(token.address, owner, ethPerToken, claimDuration);

        // Transfer tokens to the sale contract
        await token.transfer(sale.address, ether("100000"), { from: owner });
    });

    describe("buy()", () => {
        it("should allow buying tokens", async () => {
            const ethAmount = ether("1");

            await sale.buy({ from: user1, value: ethAmount });

            const details = await sale.getUserDetails(user1);
            const tokens = await sale.computeToken(ethAmount);

            expect(new BN(details.totalEtherSpent)).to.be.equal(ethAmount);
            expect(new BN(details.totalTokensAcquired)).to.be.equal(tokens);
        });

        it("should revert on zero ether", async () => {
            let reverted = false;
            try {
                await sale.buy({ value: 0 });
            } catch (error) {
                reverted = true;
                expect(error.message).to.include("ZeroEtherAmount");
            }
            expect(reverted).to.be.true;
        });

    });

    describe("claim()", () => {
        it("should allow claiming tokens after claim duration", async () => {
            const ethAmount = ether("1");
            await sale.buy({ from: user1, value: ethAmount });
            const oneSec = time.duration.seconds(1);
            await time.increase(claimDuration + oneSec);

            const balanceBefore = await token.balanceOf(user1);
            await sale.claim({ from: user1 });
            const balanceAfter = await token.balanceOf(user1);

            const tokens = await sale.computeToken(ethAmount);
            expect(balanceAfter.sub(balanceBefore)).to.be.equal(tokens);
        });

        it("should revert if nothing to claim", async () => {
            let reverted = false;
            try {
                await sale.claim();
            } catch (error) {
                reverted = true;
                expect(error.message).to.include("AlreadyClaimedAll");
            }
            expect(reverted).to.be.true;
        });

    });

    describe("computeToken()", () => {
        it("should compute correct token amount", async () => {
            const ethAmount = ether("1");
            const tokens = await sale.computeToken(ethAmount);

            const expected = (ethAmount * ether(1)) / ethPerToken;

            expect(tokens).to.be.equal(expected.toString());
        });

        it("should return zero for zero ether", async () => {
            const tokens = await sale.computeToken("0");
            expect(tokens).to.be.equal(new BN("0"));
        });
    });

    describe("getUserDetails()", () => {
        it("should return correct user details", async () => {
            const ethAmount = ether("1");
            await sale.buy({ from: user1, value: ethAmount });

            const details = await sale.getUserDetails(user1);
            const tokens = await sale.computeToken(ethAmount);

            expect(new BN(details.totalEtherSpent)).to.be.equal(ethAmount);
            expect(new BN(details.totalTokensAcquired)).to.be.equal(tokens);
            expect(new BN(details.nextPurchaseIndex)).to.be.equal(new BN("0"));
        });
    });

    describe("getUserPurchasesAt()", () => {
        it("should return correct purchase record", async () => {
            const ethAmount = ether("1");
            await sale.buy({ from: user1, value: ethAmount });

            const purchase = await sale.getUserPurchasesAt(user1, 0);
            const tokens = await sale.computeToken(ethAmount);

            expect(purchase.ethSpent).to.be.equal(ethAmount);
            expect(purchase.tokenAcquired).to.be.equal(tokens);
        });
    });

    describe("getUserAllPurchases()", () => {
        it("should return all purchases", async () => {
            await sale.buy({ from: user1, value: ether("1") });
            await sale.buy({ from: user1, value: ether("0.5") });

            const purchases = await sale.getUserAllPurchases(user1);
            expect(purchases.length).to.equal(2);
        });
    });
});
