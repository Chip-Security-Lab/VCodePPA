//SystemVerilog
module eth_ifg_controller #(parameter IFG_BYTES = 12) (
    input  wire clk,
    input  wire rst_n,
    input  wire tx_request,
    input  wire tx_done,
    output reg  tx_enable,
    output reg  ifg_active
);
    // Calculate bit width for counter to avoid excessive bits
    localparam COUNTER_WIDTH = $clog2(IFG_BYTES+1);
    
    // State definitions using one-hot encoding for better synthesis
    localparam IDLE     = 3'b001;
    localparam TRANSMIT = 3'b010;
    localparam IFG      = 3'b100;
    
    reg [2:0] state;
    reg [COUNTER_WIDTH-1:0] ifg_counter;
    
    // Optimized edge detection using single register
    reg tx_done_prev;
    wire tx_done_edge = tx_done & ~tx_done_prev;
    
    // Combined state machine with integrated counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_done_prev <= 1'b0;
            ifg_counter <= {COUNTER_WIDTH{1'b0}};
            tx_enable <= 1'b0;
            ifg_active <= 1'b0;
        end else begin
            // Edge detection update
            tx_done_prev <= tx_done;
            
            // State transition and output logic
            case (state)
                IDLE: begin
                    ifg_active <= 1'b0;
                    if (tx_request) begin
                        state <= TRANSMIT;
                        tx_enable <= 1'b1;
                    end
                end
                
                TRANSMIT: begin
                    if (tx_done_edge) begin
                        state <= IFG;
                        tx_enable <= 1'b0;
                        ifg_active <= 1'b1;
                        ifg_counter <= IFG_BYTES;
                    end
                end
                
                IFG: begin
                    // Avoid unnecessary comparison by checking if counter is already zero
                    if (ifg_counter > 1'b1) begin
                        ifg_counter <= ifg_counter - 1'b1;
                    end else begin
                        state <= IDLE;
                        ifg_active <= 1'b0;
                        ifg_counter <= {COUNTER_WIDTH{1'b0}}; // Reset counter
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule