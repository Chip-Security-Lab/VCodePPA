//SystemVerilog
module i2c_int_controller #(
    parameter FIFO_DEPTH = 8,
    parameter FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH)
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
reg [FIFO_ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
reg [7:0] fifo_out_reg;

// State definitions for interrupt state machine
localparam IDLE = 3'b000;
localparam PROCESS_INT = 3'b001;
localparam SERVICE_TX = 3'b010;
localparam SERVICE_RX = 3'b011;
reg [2:0] int_state;

// Pipeline registers for critical path cutting
reg [FIFO_ADDR_WIDTH:0] fifo_usage_stage1;
reg fifo_empty_stage1, fifo_full_stage1;
reg fifo_almost_empty_stage1;

// FIFO status signals
wire fifo_empty, fifo_full;
wire [FIFO_ADDR_WIDTH:0] fifo_usage;

// Pre-registered status signals for retiming
reg fifo_almost_empty_pre;
reg fifo_full_pre;
reg [3:0] int_status_pre;

// FIFO data output
assign fifo_data_out = fifo_out_reg;

// First pipeline stage: Calculate usage
always @(posedge clk) begin
    if (rst_sync) begin
        fifo_usage_stage1 <= {(FIFO_ADDR_WIDTH+1){1'b0}};
    end else begin
        fifo_usage_stage1 <= {1'b0, wr_ptr} - {1'b0, rd_ptr};
    end
end

// Optimized FIFO status calculation - pipelined
assign fifo_usage = fifo_usage_stage1;
assign fifo_empty = fifo_empty_stage1;
assign fifo_full = fifo_full_stage1;

// Second pipeline stage: Derive status signals
always @(posedge clk) begin
    if (rst_sync) begin
        fifo_empty_stage1 <= 1'b1;
        fifo_full_stage1 <= 1'b0;
        fifo_almost_empty_stage1 <= 1'b1;
    end else begin
        fifo_empty_stage1 <= (fifo_usage_stage1 == 0);
        fifo_full_stage1 <= (fifo_usage_stage1 == FIFO_DEPTH - 1);
        fifo_almost_empty_stage1 <= (fifo_usage_stage1 <= 1);
    end
end

// Optimized almost empty detection for earlier TX interrupt
wire fifo_almost_empty;
assign fifo_almost_empty = fifo_almost_empty_stage1;

// Pre-register combinational signals (retiming)
always @(posedge clk) begin
    if (rst_sync) begin
        fifo_almost_empty_pre <= 1'b1;
        fifo_full_pre <= 1'b0;
        int_status_pre <= 4'h0;
    end else begin
        fifo_almost_empty_pre <= fifo_almost_empty;
        fifo_full_pre <= fifo_full;
        int_status_pre <= int_status;
    end
end

// Interrupt status logic - pipelined for better timing
reg int_status_or_stage1;
always @(posedge clk) begin
    if (rst_sync) begin
        int_status_or_stage1 <= 1'b0;
    end else begin
        int_status_or_stage1 <= |int_status_pre;
    end
end

// Interrupt generation logic with retimed registers
always @(posedge clk) begin
    if (rst_sync) begin
        int_tx_empty <= 1'b0;
        int_rx_full <= 1'b0;
        int_error <= 1'b0;
        int_status <= 4'h0;
        wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
        rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
        int_state <= IDLE;
        fifo_out_reg <= 8'h00;
    end else begin
        // Check FIFO status and update interrupts using pre-registered signals
        int_tx_empty <= fifo_almost_empty_pre;
        int_rx_full <= fifo_full_pre;
        int_error <= int_status_or_stage1; // Use pipelined OR reduction
        
        // Handle FIFO operations
        if (wr_en && !fifo_full_pre) begin  // Using pre-registered status for timing
            fifo_mem[wr_ptr] <= fifo_data_in;
            wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? {FIFO_ADDR_WIDTH{1'b0}} : wr_ptr + 1'b1;
        end
        
        // State machine for interrupt processing using pre-registered signals
        case (int_state)
            IDLE: begin
                int_state <= int_status_or_stage1 ? PROCESS_INT : IDLE;
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