module i2c_int_controller #(
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_sync,           // Synchronous reset
    inout sda,
    inout scl,
    // Interrupt interface
    output reg int_tx_empty,
    output reg int_rx_full,
    output reg int_error,
    // FIFO interface
    input  wr_en,
    input  [7:0] fifo_data_in,
    output [7:0] fifo_data_out
);
// Unique feature: Interrupt system + dual-port FIFO
reg [3:0] int_status;
reg [7:0] fifo_mem[0:FIFO_DEPTH-1];
reg [3:0] wr_ptr, rd_ptr;
reg [7:0] fifo_out_reg;

// State definitions for interrupt state machine
parameter IDLE = 3'b000;
parameter PROCESS_INT = 3'b001;
parameter SERVICE_TX = 3'b010;
parameter SERVICE_RX = 3'b011;
reg [2:0] int_state;

// FIFO data output
assign fifo_data_out = fifo_out_reg;

// Interrupt generation logic
always @(posedge clk) begin
    if (rst_sync) begin
        int_tx_empty <= 1'b0;
        int_rx_full <= 1'b0;
        int_error <= 1'b0;
        int_status <= 4'h0;
        wr_ptr <= 4'h0;
        rd_ptr <= 4'h0;
        int_state <= IDLE;
        fifo_out_reg <= 8'h00;
    end else begin
        // Check FIFO status and update interrupts
        int_tx_empty <= (wr_ptr == rd_ptr + 1);
        int_rx_full  <= (rd_ptr == wr_ptr);
        int_error    <= (int_status != 0);
        
        // Handle FIFO operations
        if (wr_en && (wr_ptr != rd_ptr)) begin // Not full
            fifo_mem[wr_ptr] <= fifo_data_in;
            wr_ptr <= (wr_ptr + 1) % FIFO_DEPTH;
        end
        
        // State machine for interrupt processing
        case (int_state)
            IDLE: begin
                if (int_status != 0)
                    int_state <= PROCESS_INT;
            end
            PROCESS_INT: begin
                if (int_tx_empty)
                    int_state <= SERVICE_TX;
                else if (int_rx_full)
                    int_state <= SERVICE_RX;
                else
                    int_state <= IDLE;
            end
            SERVICE_TX, SERVICE_RX: begin
                int_state <= IDLE;
            end
            default: int_state <= IDLE;
        endcase
    end
end
endmodule