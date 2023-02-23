<template>
  <div class="buy py-5">
    <b-container>
      <b-row class="py-5">
        <b-col cols="12" md="12" class="py-5 text-center">
          <p class="text-primary mb-3 header-p">Mint</p>
          <h3>THE NFTs</h3>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<style scoped>
@media (min-width: 1024px) {
  .buy {
    background: linear-gradient(to bottom, #16171d 0%, rgba(22, 23, 29, 0) 50%), url('/images/minting-bg.png') !important;
    background-size: cover !important;
  }
}

@media (max-width: 1024px) {
  .buy {
    background: linear-gradient(to bottom, #16171d 0%, rgba(22, 23, 29, 0) 100%),url('/images/minting-mobile-bg.png') no-repeat center center / cover;
  }

}
</style>

<script>
export default {
  name: "MintingBanner"
}
</script>

