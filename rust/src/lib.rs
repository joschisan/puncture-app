use puncture_client::{Daemon, PunctureClient, PunctureConnection};
use puncture_client_core::AppEvent;
use puncture_core::invite::Invite;
use puncture_payment_request::{PaymentRequestWithAmount, PaymentRequestWithoutAmount};

#[flutter_rust_bridge::frb(opaque)]
pub struct PaymentRequestWithAmountWrapper(PaymentRequestWithAmount);

#[flutter_rust_bridge::frb(opaque)]
pub struct PaymentRequestWithoutAmountWrapper(PaymentRequestWithoutAmount);

#[flutter_rust_bridge::frb(opaque)]
pub struct InviteWrapper(Invite);

#[flutter_rust_bridge::frb(opaque)]
pub struct PunctureClientWrapper(PunctureClient);

#[flutter_rust_bridge::frb(opaque)]
pub struct DaemonWrapper(Daemon);

#[flutter_rust_bridge::frb(opaque)]
pub struct PunctureConnectionWrapper(PunctureConnection);

impl InviteWrapper {
    #[flutter_rust_bridge::frb(sync)]
    pub fn decode(invite: &str) -> Option<InviteWrapper> {
        Invite::decode(invite).map(InviteWrapper).ok()
    }
}

impl PunctureClientWrapper {
    /// Create a new puncture client instance
    #[flutter_rust_bridge::frb]
    pub async fn new_instance(data_dir: &str) -> Self {
        Self(PunctureClient::new(data_dir.to_string()).await)
    }

    /// Add a new daemon from invite
    #[flutter_rust_bridge::frb]
    pub async fn register(
        &self,
        invite: &InviteWrapper,
    ) -> Result<PunctureConnectionWrapper, String> {
        Ok(PunctureConnectionWrapper(
            self.0.register(invite.0.clone()).await?,
        ))
    }

    /// Get list of daemons
    #[flutter_rust_bridge::frb]
    pub async fn list_daemons(&self) -> Vec<DaemonWrapper> {
        self.0
            .list_daemons()
            .await
            .into_iter()
            .map(DaemonWrapper)
            .collect()
    }

    /// Delete a daemon from local db
    #[flutter_rust_bridge::frb]
    pub async fn delete_daemon(&self, daemon: DaemonWrapper) {
        self.0.delete_daemon(daemon.0).await;
    }
}

impl DaemonWrapper {
    /// Get the instance name
    #[flutter_rust_bridge::frb(sync)]
    pub fn name(&self) -> String {
        self.0.name()
    }

    /// Connect to this instance. Event though the underlying method is sync it
    /// requires a tokio runtime in order to spawn a task.
    #[flutter_rust_bridge::frb]
    pub async fn connect(&self) -> PunctureConnectionWrapper {
        PunctureConnectionWrapper(self.0.connect())
    }
}

impl PunctureConnectionWrapper {
    #[flutter_rust_bridge::frb]
    pub async fn quote(&self, amount_msat: u64) -> Result<u64, String> {
        self.0
            .fees()
            .await
            .map(|fees| (amount_msat * fees.fee_ppm) / 1_000_000 + fees.base_fee_msat)
    }

    #[flutter_rust_bridge::frb]
    pub async fn send(&self, request: &PaymentRequestWithAmountWrapper) -> Result<(), String> {
        match &request.0 {
            PaymentRequestWithAmount::Bolt11(bolt11) => {
                self.0
                    .bolt11_send(
                        bolt11.invoice.clone(),
                        bolt11.amount_msat,
                        bolt11.ln_address.clone(),
                    )
                    .await
            }
            PaymentRequestWithAmount::Bolt12(bolt12) => {
                self.0
                    .bolt12_send(bolt12.offer.clone(), bolt12.amount_msat)
                    .await
            }
        }
    }

    /// Create a bolt11 invoice for receiving payments
    #[flutter_rust_bridge::frb]
    pub async fn bolt11_receive(
        &self,
        amount_msat: u32,
        description: &str,
    ) -> Result<String, String> {
        self.0
            .bolt11_receive(amount_msat, description.to_string())
            .await
            .map(|invoice| invoice.to_string())
    }

    /// Create a static bolt12 offer for receiving payments
    /// with a variable amount and no expiration
    #[flutter_rust_bridge::frb]
    pub async fn bolt12_receive_variable_amount(&self) -> Result<String, String> {
        self.0.bolt12_receive_variable_amount().await
    }

    /// Get the next event from the daemon
    #[flutter_rust_bridge::frb]
    pub async fn next_event(&self) -> Event {
        match self.0.next_event().await {
            AppEvent::Payment(payment) => Event::Payment(PaymentEvent {
                id: payment.id,
                payment_type: payment.payment_type,
                is_live: payment.is_live,
                amount_msat: payment.amount_msat,
                fee_msat: payment.fee_msat,
                description: payment.description,
                status: payment.status,
                ln_address: payment.ln_address,
                created_at: payment.created_at,
            }),
            AppEvent::Balance(balance) => Event::Balance(BalanceEvent {
                amount_msat: balance.amount_msat,
            }),
            AppEvent::Update(update) => Event::Update(UpdateEvent {
                id: update.id,
                status: update.status,
            }),
        }
    }
}

#[flutter_rust_bridge::frb]
pub enum Event {
    Payment(PaymentEvent),
    Balance(BalanceEvent),
    Update(UpdateEvent),
}

#[flutter_rust_bridge::frb]
pub struct PaymentEvent {
    pub id: String,
    pub payment_type: String,
    pub is_live: bool,
    pub amount_msat: i64,
    pub fee_msat: i64,
    pub description: String,
    pub status: String,
    pub ln_address: Option<String>,
    pub created_at: i64,
}

#[flutter_rust_bridge::frb]
pub struct BalanceEvent {
    pub amount_msat: u64,
}

#[flutter_rust_bridge::frb]
pub struct UpdateEvent {
    pub id: String,
    pub status: String,
}

impl PaymentRequestWithAmountWrapper {
    #[flutter_rust_bridge::frb(sync)]
    pub fn display(&self) -> String {
        match &self.0 {
            PaymentRequestWithAmount::Bolt11(request) => {
                format!("Invoice for {} sats", request.amount_msat / 1000)
            }
            PaymentRequestWithAmount::Bolt12(request) => {
                format!("Offer for {} sats", request.amount_msat / 1000)
            }
        }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn amount_msat(&self) -> u64 {
        self.0.amount_msat()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn description(&self) -> String {
        self.0.description()
    }
}

impl PaymentRequestWithoutAmountWrapper {
    #[flutter_rust_bridge::frb(sync)]
    pub fn display(&self) -> String {
        match &self.0 {
            PaymentRequestWithoutAmount::Bolt11(..) => "Bolt11 Invoice".to_string(),
            PaymentRequestWithoutAmount::Bolt12(..) => "Bolt12 Offer".to_string(),
            PaymentRequestWithoutAmount::LnUrl(..) => "LnUrl".to_string(),
            PaymentRequestWithoutAmount::LightningAddress(address) => address.to_string(),
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn parse_with_amount(request: &str) -> Option<PaymentRequestWithAmountWrapper> {
    puncture_payment_request::parse_with_amount(request.to_string())
        .map(PaymentRequestWithAmountWrapper)
}

#[flutter_rust_bridge::frb(sync)]
pub fn parse_without_amount(request: &str) -> Option<PaymentRequestWithoutAmountWrapper> {
    puncture_payment_request::parse_without_amount(request.to_string())
        .map(PaymentRequestWithoutAmountWrapper)
}

#[flutter_rust_bridge::frb]
pub async fn resolve_payment_request(
    request: &PaymentRequestWithoutAmountWrapper,
    amount: u64,
) -> Result<PaymentRequestWithAmountWrapper, String> {
    puncture_payment_request::resolve(&request.0, amount)
        .await
        .map(PaymentRequestWithAmountWrapper)
}
