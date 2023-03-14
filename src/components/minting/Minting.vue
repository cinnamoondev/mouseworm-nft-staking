<template>
  <b-container class="py-3">
    <header>
      <div class="d-flex flex-column flex-md-row align-items-center pb-3 mb-4">
        <a href="/" class="d-flex align-items-center text-dark text-decoration-none d-block d-sm-block d-md-none">
          <img src="/images/logo-mouseworm-01.png" alt="Mouseworm Logo" width="300">
        </a>
        <nav class="d-inline-flex mt-2 mt-md-0 ms-md-auto ml-md-auto">
          <button class="btn btn-connect me-2" type="button" v-if="user === null" @click="connect">Connect yo wallet
          </button>
        </nav>
      </div>
      <div class="pricing-header p-3 pb-md-4 mx-auto text-center">
      </div>
    </header>
    <main class="nft">
      <b-row class="relative">
        <b-col cols="12" class="col-md logo-title">
          <b-img src="/images/title-mouseworm-nfts.svg" alt="Mouseworm Logo"></b-img>
          <div class="card mainBG six-hands-brush txt-lg px-5 px-lg-5 px-xxl-5 py-3 m-4 m-md-0">
            <p class="pe-1 pe-md-3 pe-lg-5">Mint an NFT from our exclusive collection.
              Only <strong>100 will be minted</strong> and they will receive rewards going forward.</p>
          </div>
          <div class="wormie"><img src="/images/icon-wormie.png" width="100"></div>
        </b-col>
        <div class="col-6 col-md-6 logoBG">
          <img src="/images/logo-mouseworm-01.png" alt="Mouseworm Logo" class="d-none d-md-block d-lg-block d-md-block">
        </div>
      </b-row>
      <div class="container">
        <div class="row">
          <div class="col-12">
            <b-tabs pills justified class="nav-fill">
              <b-tab title="Mint" active class="dk-blue">
                <b-row class="pt-md-5">
                  <b-col cols="12" lg="6" class="card py-4 py-lg-5 my-5 text-center ms-1 ms-lg-5 mint">
                    <b-container v-if="isPaused !== false">
                      <b-row class="text-center txt-md py-5">
                        <b-col cols="12">
                          Sale not started yet
                        </b-col>
                      </b-row>
                    </b-container>
                    <b-container v-else-if="size <= requiredSize">
                      <b-row class="text-center txt-md py-5">
                        <b-col cols="12">
                          You have to hold at least {{ fromWei(requiredSize, 6) }} MouseWorm to mint {{ size }}
                        </b-col>
                      </b-row>
                    </b-container>
                    <b-container v-else-if="maxNFTAmount <= sizeNFT">
                      <b-row class="text-center txt-md py-5">
                        <b-col cols="12">
                          You already minted maximum amount of NFTs
                        </b-col>
                      </b-row>
                    </b-container>
                    <b-container v-else>
                      <b-row>
                        <b-col cols="6" class="ps-0 ps-md-5 ps-lg-5 mint-amount">
                          <b-form-spinbutton name="amount" v-model="amount" min="1"
                                             :max="maxNFTAmount - sizeNFT"
                                             style="border: 5px solid #AB2E9A !important;"></b-form-spinbutton>
                        </b-col>
                        <b-col cols="6" class=" text-right pe-1 pe-md-5 pe-lg-5">
                          <vue-loading-button class="btn btn-mint" :style="false" :loading="mintLoading"
                                              @click.native="mint">Mint
                          </vue-loading-button>
                        </b-col>
                      </b-row>
                      <b-row class="text-center txt-md pt-2 pt-lg-5">
                        <b-col>
                          Cost to Mint: {{ fromWei(price.muln(amount), 18) }} ETH
                        </b-col>
                      </b-row>
                    </b-container>
                  </b-col>
                  <b-col cols="12" lg="5" class="txt-lg six-hands-brush mt-5 pt-lg-5 ps-lg-5">
                    <b-row>
                      <b-col cols="6" class="dk-blue">Minted:</b-col>
                      <b-col cols="6" class="white">{{ sizeNFT }} / {{ maxNFTAmount }}</b-col>
                    </b-row>
                    <b-row>
                      <b-col cols="6" class="dk-blue">Total Minted:</b-col>
                      <b-col cols="6" class="white">{{ minted }} / 100</b-col>
                    </b-row>
                  </b-col>
                </b-row>
              </b-tab>
              <b-tab title="Stake" class="dk-blue">
                <b-row class="pt-md-5">
                  <b-col cols="12" lg="6" class="mt-5 text-center">
                    <b-container class="card mint py-4 py-lg-5 ms-1 ms-lg-5">
                      <h3>Stake your NFTs</h3>
                      <b-row class="text-center">
                        <b-col class="mt-3 mt-md-0" cols="12" v-if="availableNFTs.length > 0">
                          <b-row class="mt-3 mt-md-0">
                            <b-col cols="4" class="mt-3" v-for="(item) in availableNFTs" :key="item">
                              <figure>
                                <b-img :src="`http://164.92.242.36:8090/media/${parseInt(item)}`" fluid
                                       :class="selectedNFT == item ? 'selected' : ''"
                                       @click="selectNFT(item)"></b-img>

                                <figcaption class="text-center small">NFT #{{ parseInt(item) + 1 }}</figcaption>
                              </figure>
                            </b-col>
                          </b-row>
                          <b-row class="mt-3 mt-md-0" v-if="availableNFTs.length > 0">
                            <b-col>
                              <p>Select lock duration</p>
                              <label for="one">
                                <input type="radio" id="one" name="duration" v-model="lockDuration" value="0"
                                       :disabled="(unlockTime - new Date().getTime() / 1000) > 0">
                                <span class="btn">No lock</span>
                              </label>
                              <label for="two">
                                <input type="radio" id="two" name="duration" v-model="lockDuration" value="30"
                                       :disabled="(unlockTime - new Date().getTime() / 1000) > 30 * DAY">
                                <span class="btn">30 days</span>
                              </label>
                              <label for="three">
                                <input type="radio" id="three" name="duration" v-model="lockDuration" value="60"
                                       :disabled="(unlockTime - new Date().getTime() / 1000) > 60 * DAY">
                                <span class="btn">60 days</span>
                              </label>
                              <label for="four">
                                <input type="radio" id="four" name="duration" v-model="lockDuration" value="90"
                                       :disabled="(unlockTime - new Date().getTime() / 1000) > 90 * DAY">
                                <span class="btn">90 days</span>
                              </label>
                            </b-col>
                          </b-row>
                          <div class="row align-items-center mt-3 justify-content-between">
                            <div class="col-md-12 col-lg-12 text-center">
                              <div v-if="nftAllowed == 1">
                                <VueLoadingButton
                                    v-if="availableNFTs.length > 0 && this.availableNFTs.includes(selectedNFT)"
                                    aria-label="Stake" @click.native="stakeNFTs"
                                    class="btn btn-primary bg-primary text-white" :styled="false"
                                    :loading="nftStakeLoading">Stake
                                </VueLoadingButton>
                              </div>
                              <div v-else>
                                <VueLoadingButton aria-label="Stake" @click.native="approveNFTs"
                                                  class="btn btn-mint text-white"
                                                  :loading="nftApproveLoading" :styled="false">Allow staking contract to
                                  use
                                  your
                                  NFTs
                                </VueLoadingButton>
                              </div>
                            </div>
                          </div>
                        </b-col>
                        <b-col v-else class="text-center mt-5">
                          You don't have NFTs. Click
                          <b-link href="/">here</b-link>
                          to mint!
                        </b-col>
                      </b-row>

                    </b-container>
                  </b-col>
                  <b-col cols="12" lg="6" class="my-5 text-center">
                    <b-container class=" card mint py-4 py-lg-5 ms-1 ms-lg-5">
                      <h3>Withdraw Staked NFTs</h3>
                      <b-row class="my-5">
                        <b-col class="mt-3 mt-md-0" cols="12" v-if="stakedNFTs.length > 0">
                          <b-row>
                            <b-col cols="4" v-for="(item) in stakedNFTs" :key="item">
                              <figure>
                                <b-img :src="`http://164.92.242.36:8090/media/${parseInt(item)}`" fluid
                                       :class="selectedNFT == item ? 'selected' : ''"
                                       @click="selectNFT(item)"></b-img>
                                <figcaption class="text-center">NFT #{{ parseInt(item) + 1 }}</figcaption>
                              </figure>
                            </b-col>
                          </b-row>
                          <div class="row align-items-center mt-3 justify-content-between">
                            <div class="col-md-12 col-lg-12 text-center">
                              <div v-if="(unlockTime - new Date().getTime() / 1000) * 1000 > 0"
                                   class="text-center my-3">
                                <vue-countdown
                                    :time="(unlockTime - new Date().getTime() / 1000) * 1000">
                                  <template slot-scope="props">
                                    Locked for
                                    <span class="highlight"><span v-if="props.days > 0">{{ props.days }} D </span>{{
                                        String("00" + props.hours).slice(-2)
                                      }}:{{ String("00" + props.minutes).slice(-2) }}:{{
                                        String("00" + props.seconds).slice(-2)
                                      }}</span>
                                  </template>
                                </vue-countdown>
                              </div>
                              <div v-else class="my-3">
                                <VueLoadingButton v-if="stakedNFTs.length > 0 && this.stakedNFTs.includes(selectedNFT)"
                                                  aria-label="Stake" @click.native="withdrawNFTs"
                                                  class="btn btn-primary bg-primary mr-2 text-white" :styled="false"
                                                  :loading="nftWithdrawLoading">Withdraw
                                </VueLoadingButton>
                              </div>
                            </div>
                          </div>
                        </b-col>
                        <b-col v-else class="text-center">
                          You don't have staked NFTs
                        </b-col>
                      </b-row>
                    </b-container>
                  </b-col>
                </b-row>
              </b-tab>
              <b-tab title="Rewards" class="dk-blue">
                <b-row class="pt-md-5">
                  <b-col cols="12" lg="12" class="card py-4 py-lg-5 my-5 text-center ms-1 ms-lg-5 mint">
                    <b-container>
                      <b-row class="text-center txt-md">
                        <b-col>
                          <p>Total claimed: {{ beautifyRewards(fromWei(userInfo.withdrawn, 18)) }} ETH</p>
                          <p>Total unclaimed: {{ beautifyRewards(fromWei(rewardsETH, 18)) }} ETH</p>
                          <VueLoadingButton aria-label="Stake" @click.native="claimETH(0)" v-if="rewardsETH > 0"
                                            class="btn btn-mint"
                                            :loading="stakeLoading" :styled="false">Claim rewards
                          </VueLoadingButton>&nbsp;
                          <p class="text-center text-muted mt-3">
                            Claim will transfer your ETH rewards from staking contract to your wallet
                          </p>
                        </b-col>
                      </b-row>
                    </b-container>
                  </b-col>
                </b-row>
              </b-tab>
            </b-tabs>
          </div>
        </div>
      </div>
    </main>
  </b-container>
</template>

<style scoped>
.selected {
  border: solid 5px rgb(232, 51, 218);
}

.form-control.b-form-spinbutton, .form-control.b-form-spinbutton input, .form-control.b-form-spinbutton:focus, .form-control.b-form-spinbutton:active, .form-control.b-form-spinbutton.focus {
  background-color: transparent !important;
  color: #000 !important;
  box-shadow: none !important;
  border: 1px solid #fff !important;
}

.b-form-spinbutton .btn {
  color: #000000 !important;
}

.text-lg {
  font-size: 24px;
  font-weight: bold;
}

label {
  width: 25%;
}

label input {
  position: absolute;
  opacity: 0;
  cursor: pointer;
  height: 0;
  width: 0;
}

label span.btn {
  margin-right: 0;
  background: transparent !important;
  color: #000000;
  border: solid 1px #39393f;
  border-radius: 0;
  font-size: 14px;
  width: 100%;
}


input:disabled + .btn {
  background-color: #373739;
  color: #ffffff !important;
  cursor: not-allowed;
}

input:checked:not(:disabled) + .btn {
  background: linear-gradient(323.98deg, #7F0799 11.1%, #C93DB6 66.32%) !important;
  color: #fff !important;
}
</style>

<script>
import Web3 from "web3"
import NFT from "@/helper/contracts/nft"
import MW from "@/helper/contracts/mw"
import MWLP from "@/helper/contracts/mw-lp"
import STAKING from '@/helper/contracts/staking'
import TETHER from '@/helper/contracts/tether'

import VueLoadingButton from "vue-loading-button";
import VueCountdown from "@chenfengyuan/vue-countdown";


export default {
  name: "Minting",
  components: {VueLoadingButton, VueCountdown},
  data: function () {
    return {
      DAY: 86400,
      isObservationEnabled: false,
      user: null,
      nftContract: null,
      stakingContract: null,
      selectedNFT: null,
      availableNFTs: [],
      stakedNFTs: [],
      contract: null,
      showAlert: false,
      mintLoading: false,
      isRevealed: false,
      lockDuration: 0,
      nftAllowed: 0,
      unlockTime: 0,
      amount: 1,
      price: Web3.utils.toBN(0),
      minted: Web3.utils.toBN(0),
      isPaused: false,
      requiredSize: Web3.utils.toBN("100000000"),
      userNFTs: [],
      size: Web3.utils.toBN(0),
      sizeNFT: 0,
      maxNFTAmount: 0,
      maxSupply: Web3.utils.toBN(0),
      rewardsETH: Web3.utils.toBN(0),
      poolId: 0,
      userInfo: {
        boostPointsBP: 0,
        lockTimeBoost: 0,
        lockedUntil: 0,
        claimableETH: 0,
        weightedBalance: 0,
        withdrawn: Web3.utils.toBN(0),
        ETHrewardDebt: 0,
      },
      poolInfo: {
        lpToken: 0,
        allocPoint: 0,
        lastRewardBlock: 0,
        accRwtPerShare: 0,
        accETHPerShare: 0,
        weightedBalance: 0,
      },
      stakeLoading: false,
      nftStakeLoading: false,
      nftWithdrawLoading: false,
      nftApproveLoading: false,
    }
  },
  methods: {
    beautifyNumbers: function (number) {
      if (number >= 1000000000) {
        return Math.round(number / 1000000000 * 100) / 100 + 'B'
      } else if (number >= 1000000) {
        return Math.round(number / 1000000 * 100) / 100 + 'M'
      } else if (number >= 1000) {
        return Math.round(number / 1000 * 100) / 100 + 'K'
      } else {
        return Math.round(number * 100) / 100;
      }
    },
    beautifyRewards: function (number) {
      if (parseFloat(number) === 0) {
        return 0.00;
      } else if (parseFloat(number) < 0.0001) {
        return '< 0.0001'
      } else {
        return this.format(number, 6)
      }
    },
    beautifyWallet: function (address) {
      return address.slice(0, 6) + '...' + address.slice(-6)
    },
    format: function (number, decimals = 0) {
      return new Intl.NumberFormat('en-US', {
        minimumFractionDigits: decimals,
        maximumFractionDigits: decimals
      }).format(number)
    },
    start: async function () {
      /*****************************************/
      /* Detect the MetaMask Ethereum provider */
      /*****************************************/

      // this returns the provider, or null if it wasn't detected
      //const provider = await detectEthereumProvider();
      const provider = window.ethereum;

      if (provider) {
        this.startApp(provider); // Initialize your app
      }


      /***********************************************************/
      /* Handle user accounts and accountsChanged (per EIP-1193) */
      /***********************************************************/

      window.ethereum
          .request({method: 'eth_accounts'})
          .then(this.handleAccountsChanged)
          .catch((err) => {
            // Some unexpected error.
            // For backwards compatibility reasons, if no accounts are available,
            // eth_accounts will return an empty array.
            console.error(err);
          });
    },
    startApp: function (provider) {
      // If the provider returned by detectEthereumProvider is not the same as
      // window.ethereum, something is overwriting it, perhaps another wallet.
      if (provider !== window.ethereum) {
        console.error('Do you have multiple wallets installed?');
      }

      //connect to the contract
      let web3js = new Web3(provider);
      this.nftContract = new web3js.eth.Contract(NFT.abi, NFT.address);
      this.contract = new web3js.eth.Contract(MW.abi, MW.address);
      this.stakingContract = new web3js.eth.Contract(STAKING.abi, STAKING.address)
      if (this.chainId !== 5) {
        this.usdtCtr = new web3js.eth.Contract(TETHER.abi, TETHER.address)
      }
      this.uniPair = new web3js.eth.Contract(MWLP.abi, MWLP.address)


      web3js.eth.getChainId().then((id) => {
        if (id != MW.chain) {
          this.showAlert = true
        } else {
          this.showAlert = false
          //recursively get total supply
          const refreshTotalSupply = () => {
            this.getUser()
            this.getSize()
            this.getSaleState()
            this.getPrice()
            this.getNFTSize()
            this.getMaxNFTAmount()
            this.getMaxSupply()
            this.getUserNFTs()
            this.getIsRevealed()
            this.getDepositedNFTs()
            this.getPoolInfo()
            this.getEthPrice()
            this.getRewardsETH()
            this.getThePrice()
            this.getNFTApproval()
            // eslint-disable-next-line
            this.getTotalSupply().finally(r => {
              setTimeout(refreshTotalSupply, 500);
            });
          }

          refreshTotalSupply();
        }
      });
    },
    fromWei: function (number, num) {
      if (typeof number === "undefined") {
        return 0;
      }
      let type = 'ether'

      if (num === 6) {
        type = "picoether"
      }

      return Web3.utils.fromWei(number, type)
    },
    toWei: function (number, num) {

      let type = 'ether'

      if (num === 6) {
        type = "picoether"
      }

      return Web3.utils.toWei(number, type)
    },
    stakeNFTs: function () {
      let t = this;

      if (this.availableNFTs.includes(this.selectedNFT)) {
        this.nftStakeLoading = true
        console.log(0, NFT.address, parseInt(this.selectedNFT), this.lockDuration * this.DAY)
        return this.stakingContract.methods.depositNFT(0, NFT.address, parseInt(this.selectedNFT), this.lockDuration * this.DAY)
            .send({from: this.user, value: 0})
            .on("receipt", function () {
              t.nftStakeLoading = false
            })
            .on("error", function () {
              t.nftStakeLoading = false
            })
      } else {
        alert("Please select one of the available NFTs")
      }
    },
    getUser: async function () {
      if (this.user) {
        this.stakingContract.methods.userInfo(this.poolId, this.user).call().then(res => {
          this.userInfo = res

          if (this.unlockTime != res.lockedUntil) {
            this.unlockTime = res.lockedUntil
          }

        }).catch(err => console.log("getUser: " + err))
      }

      return this
    },
    getPoolInfo: async function () {
      if (this.user) {
        this.stakingContract.methods.poolInfo(this.poolId).call().then(res => {
          this.poolInfo = res
        }).catch(err => console.log("getPoolInfo: " + err))
      }

      return this
    },
    getRewardsETH: function () {
      if (this.user) {
        this.stakingContract.methods.pendingRewards(this.poolId, this.user).call().then(res => {
          this.rewardsETH = Web3.utils.toBN(res)
        }).catch(err => console.log("pendingRewards: " + err))
      }
      return this
    },
    getEthPrice: async function () {
      if (MW.chain == 5) {
        this.ethPrice = 1600
      } else {
        this.usdweth = 0;

        await this.usdtCtr.methods.token0().call().then(res => {
          if (res.toString().toLowerCase() === (TETHER.address).toString().toLowerCase()) {
            this.usdweth = 1
          }
        })

        return this.usdtCtr.methods.getReserves().call().then(res => {
          if (this.usdweth === 0) {
            this.ethPrice = (res[1] / 10 ** 6) / (res[0] / 10 ** 18)
          } else {
            this.ethPrice = (res[0] / 10 ** 6) / (res[1] / 10 ** 18)
          }
        }).catch(err => console.log("getUniPairReserves: " + err))
      }
    },
    getThePrice: async function () {
      this.weth = 0;

      await this.uniPair.methods.token0().call().then(res => {
        if (res.toString().toLowerCase() === (MW.address).toString().toLowerCase()) {
          this.weth = 1
        }
      })

      return this.uniPair.methods.getReserves().call().then(res => {
        if (this.weth === 0) {
          this.thePriceEth = (res[0] / 10 ** 18) / (res[1] / 10 ** 18)
        } else {
          this.thePriceEth = (res[1] / 10 ** 18) / (res[0] / 10 ** 18)
        }
        this.thePrice = this.thePriceEth * this.ethPrice

      }).catch(err => console.log("getUniPairReserves: " + err))
    },
    withdrawNFTs: function () {
      let t = this;
      if (this.stakedNFTs.includes(this.selectedNFT)) {

        this.nftWithdrawLoading = true

        return this.stakingContract.methods.withdrawNFT(0, NFT.address, parseInt(this.selectedNFT))
            .send({from: this.user, value: 0})
            .on("receipt", function () {
              t.nftWithdrawLoading = false
            })
            .on("error", function () {
              t.nftWithdrawLoading = false
            })
      } else {
        alert("Please select one of the staked NFTs")
      }
    },
    getNFTApproval: async function () {
      if (this.user) {
        return this.nftContract.methods.isApprovedForAll(this.user, STAKING.address).call().then(res => {
          this.nftAllowed = res;
        })
      }

      return false
    },
    approveNFTs: async function () {
      this.nftApproveLoading = true
      let t = this
      return this.nftContract.methods.setApprovalForAll(STAKING.address, true).send({
        from: this.user,
        value: 0
      }).on("receipt", function () {
        t.nftApproveLoading = false
      }).on("error", function () {
        t.nftApproveLoading = false
      })
    },
    selectNFT: function (id) {
      if (id === this.selectedNFT) {
        this.selectedNFT = null
      } else {
        this.selectedNFT = id
      }
    },
    claimETH: async function (pid) {
      let t = this;
      this.stakeLoading = true

      return this.stakingContract.methods.claimETH(pid)
          .send({from: this.user, value: 0})
          .on("receipt", function () {
            // t.$notification.success("Successfully claimed ETH rewards", {timer: 10});
            t.stakeLoading = false
          })
          .on("error", function () {
            // t.$notification.error("An error occurred while trying to claim earned ETH", {timer: 10});
            t.stakeLoading = false
          });
    },
    getDepositedNFTs: function () {
      if (this.user) {
        this.stakingContract.methods.getUsersNFTs(0, this.user).call().then(res => {
          this.stakedNFTs = res[1]
        }).catch(err => console.log("getUser: " + err))
      }
      return this
    },
    getTotalSupply: function () {
      return this.nftContract.methods.totalSupply().call().then(res => {
        this.minted = Web3.utils.toBN(res)
      });
    },
    getIsRevealed: function () {
      return this.nftContract.methods._isRevealed().call().then(res => {
        this.isRevealed = res
      });
    },
    getSaleState: function () {
      this.nftContract.methods._paused().call().then(res => {
        this.isPaused = res
      })
    },
    getPrice: function () {
      if (this.user != null) {
        this.nftContract.methods.getPrice().call().then(res => {
          this.price = Web3.utils.toBN(res)
        })
      }
    },
    getSize: function () {
      if (this.user != null) {
        return this.contract.methods.balanceOf(this.user).call().then(res => {
          this.size = Web3.utils.toBN(res)
        }).catch(err => {
          console.log("getSize:")
          console.log(err)
        })
      }
      return this
    },
    getNFTSize: async function () {
      if (this.user) {
        return this.nftContract.methods.walletOfOwner(this.user).call().then(res => {
          this.availableNFTs = res;
          this.sizeNFT = parseFloat(res.length)
        })
      }

      return false
    },
    getUserNFTs: function () {
      if (this.user !== null && this.sizeNFT > 0) {
        this.nftContract.methods.walletOfOwner(this.user).call().then(res => {
          this.userNFTs = res
        })
      }
    },
    getMaxNFTAmount: function () {
      if (this.user !== null) {
        this.nftContract.methods._maxNFTAmount().call().then(res => {
          this.maxNFTAmount = parseFloat(res)
        })
      }
    },
    getMaxSupply: function () {
      if (this.user !== null) {
        this.nftContract.methods._maxSupply().call().then(res => {
          this.maxSupply = Web3.utils.toBN(res)
        })
      }
    },
    handleAccountsChanged: function (accounts) {
      if (accounts.length === 0) {
        this.connect();
      } else if (accounts[0] !== this.user) {
        this.user = accounts[0];
      }
    },
    connect() {
      window.ethereum
          .request({method: 'eth_requestAccounts'})
          .then(this.handleAccountsChanged)
          .catch((err) => {
            if (err.code === 4001) {
              // EIP-1193 userRejectedRequest error
              // If this happens, the user rejected the connection request.
              console.log('Please connect to MetaMask.');
            } else {
              console.error(err);
            }
          });
    },
    mint() {
      let eth = this.amount * this.price;
      var that = this

      that.mintLoading = true;

      return this.nftContract.methods.mint(this.amount)
          .send({from: this.user, value: eth})
          .on("receipt", function () {
            that.mintLoading = false;
            console.log("Mint successful")
          })
          .on("error", function () {
            that.mintLoading = false;
            console.log("Mint failed")
          });
    }
  },
  mounted() {
    this.start()
    window.ethereum.on('accountsChanged', this.handleAccountsChanged);
    window.ethereum.on('chainChanged', this.start);
  }
}
</script>