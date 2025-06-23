mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

use puncture_client::{PunctureClient, PunctureConnection, Instance};
use puncture_core::user::AppEvent;

#[flutter_rust_bridge::frb(opaque)]
pub struct PunctureClientWrapper(PunctureClient);

#[flutter_rust_bridge::frb(opaque)]
pub struct InstanceWrapper(Instance);

#[flutter_rust_bridge::frb(opaque)]
pub struct PunctureConnectionWrapper(PunctureConnection);


impl PunctureClientWrapper {
    /// Create a new puncture client store instance
    #[flutter_rust_bridge::frb]
    pub async fn new_instance(data_dir: String) -> Self {
        Self(PunctureClient::new(data_dir).await)
    }

    /// Add a new instance from invite
    #[flutter_rust_bridge::frb]
    pub async fn add_instance(&self, invite: String) -> Result<PunctureConnectionWrapper, String> {
        Ok(PunctureConnectionWrapper(self.0.add_instance(invite).await?))
    }

    /// Get list of instances
    #[flutter_rust_bridge::frb(sync)]
    pub fn get_instances(&self) -> Vec<InstanceWrapper> {
        self.0.get_instances().into_iter().map(InstanceWrapper).collect()
    }
}


impl InstanceWrapper {
    /// Get the instance name
    #[flutter_rust_bridge::frb(sync)]
    pub fn name(&self) -> String {
        self.0.name()
    }

    /// Get the invite string for this instance
    #[flutter_rust_bridge::frb(sync)]
    pub fn invite(&self) -> String {
        self.0.invite()
    }

    /// Connect to this instance. Event though the underlying method is sync it 
    /// requires a tokio runtime in order to spawn a task.
    #[flutter_rust_bridge::frb]
    pub async fn connect(&self) -> PunctureConnectionWrapper {
        PunctureConnectionWrapper(self.0.connect())
    }
}


impl PunctureConnectionWrapper {
    /// Create a bolt11 invoice for receiving payments
    #[flutter_rust_bridge::frb]
    pub async fn bolt11_receive(
        &self,
        amount_msat: u32,
        description: Option<String>,
    ) -> Result<String, String> {
        self.0.bolt11_receive(amount_msat, description).await
    }

    /// Send a bolt11 payment
    #[flutter_rust_bridge::frb]
    pub async fn bolt11_send(
        &self,
        invoice: String,
        ln_address: Option<String>,
    ) -> Result<(), String> {
        self.0.bolt11_send(invoice, ln_address).await
    }

    /// Quote a bolt11 payment (get fees and details)
    #[flutter_rust_bridge::frb]
    pub async fn bolt11_quote(&self, invoice: String) -> Result<QuoteResponse, String> {
        let response = self.0.bolt11_quote(invoice).await?;

        Ok(QuoteResponse {
            amount_msat: response.amount_msat,
            fee_msat: response.fee_msat,
            description: response.description,
            expiry_secs: response.expiry_secs,
        })
    }

    /// Get the next event from the daemon
    #[flutter_rust_bridge::frb]
    pub async fn next_event(&self) -> Event {
        let app_event = self.0.next_event().await;

        match app_event {
            AppEvent::Payment(payment) => Event::Payment(PaymentEvent {
                id: payment.id,
                payment_type: payment.payment_type,
                amount_msat: payment.amount_msat,
                fee_msat: payment.fee_msat,
                description: payment.description,
                bolt11_invoice: payment.bolt11_invoice,
                created_at: payment.created_at,
                status: payment.status,
                ln_address: payment.ln_address,
            }),
            AppEvent::Balance(balance) => Event::Balance(BalanceEvent { msat: balance.msat }),
            AppEvent::Update(update) => Event::Update(UpdateEvent {
                id: update.id,
                status: update.status,
            }),
        }
    }
}

#[flutter_rust_bridge::frb]
pub struct QuoteResponse {
    pub amount_msat: u64,
    pub fee_msat: u64,
    pub description: String,
    pub expiry_secs: u64,
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
    pub amount_msat: i64,
    pub fee_msat: i64,
    pub description: String,
    pub bolt11_invoice: String,
    pub created_at: i64,
    pub status: String,
    pub ln_address: Option<String>,
}

#[flutter_rust_bridge::frb]
pub struct BalanceEvent {
    pub msat: u64,
}

#[flutter_rust_bridge::frb]
pub struct UpdateEvent {
    pub id: String,
    pub status: String,
}


