//SystemVerilog
module i2c_slave_async(
    input  wire        rst_n,
    input  wire [6:0]  device_addr,
    output reg  [7:0]  data_received,
    output wire        data_valid,
    inout  wire        sda,
    inout  wire        scl
);

// ============================================================================
// Internal signals and pipeline registers
// ============================================================================
wire        scl_sync, scl_sync_prev;
wire        sda_sync, sda_sync_prev;

reg  [6:0]  addr_stage1;
reg  [7:0]  data_stage1, data_stage2;
reg  [3:0]  bit_count_stage1, bit_count_stage2;
reg         addr_matched_stage1, addr_matched_stage2;
reg         receiving_stage1, receiving_stage2;

reg         data_valid_reg;
reg         data_latched;

// ============================================================================
// Input Synchronization (to avoid metastability on asynchronous I2C lines)
// ============================================================================
sync_3stage #(
    .SYNC_WIDTH(1)
) u_scl_sync (
    .clk(scl),
    .rst_n(rst_n),
    .async_in(scl),
    .sync_out(scl_sync),
    .sync_out_prev(scl_sync_prev)
);

sync_3stage #(
    .SYNC_WIDTH(1)
) u_sda_sync (
    .clk(scl),
    .rst_n(rst_n),
    .async_in(sda),
    .sync_out(sda_sync),
    .sync_out_prev(sda_sync_prev)
);

// ============================================================================
// START/STOP Detection (combinational)
// ============================================================================
wire start_condition = (sda_sync_prev && !sda_sync && scl_sync);
wire stop_condition  = (!sda_sync_prev && sda_sync && scl_sync);

wire scl_rising_edge  = (!scl_sync_prev && scl_sync);
wire scl_falling_edge = (scl_sync_prev && !scl_sync);

// ============================================================================
// Pipeline Stage 1: START/STOP and Address Reception
// ============================================================================
always @(posedge scl_sync or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1           <= 7'd0;
        data_stage1           <= 8'd0;
        bit_count_stage1      <= 4'd0;
        addr_matched_stage1   <= 1'b0;
        receiving_stage1      <= 1'b0;
    end else begin
        if (start_condition) begin
            bit_count_stage1     <= 4'd0;
            addr_stage1         <= 7'd0;
            addr_matched_stage1 <= 1'b0;
            receiving_stage1    <= 1'b1;
        end else if (receiving_stage1) begin
            if (bit_count_stage1 < 4'd7) begin
                addr_stage1[6-bit_count_stage1] <= sda_sync;
                bit_count_stage1 <= bit_count_stage1 + 1'b1;
            end else if (bit_count_stage1 == 4'd7) begin
                addr_stage1[0] <= sda_sync;
                addr_matched_stage1 <= (addr_stage1 == device_addr);
                bit_count_stage1 <= bit_count_stage1 + 1'b1;
            end else if (bit_count_stage1 == 4'd8) begin
                // ACK/NACK bit, skip
                bit_count_stage1 <= bit_count_stage1 + 1'b1;
            end else begin
                // Wait for next transaction
                receiving_stage1 <= 1'b0;
            end
        end
        if (stop_condition) begin
            receiving_stage1 <= 1'b0;
        end
    end
end

// ============================================================================
// Pipeline Stage 2: Data Reception
// ============================================================================
always @(posedge scl_sync or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2           <= 8'd0;
        bit_count_stage2      <= 4'd0;
        addr_matched_stage2   <= 1'b0;
        receiving_stage2      <= 1'b0;
        data_latched          <= 1'b0;
    end else begin
        addr_matched_stage2 <= addr_matched_stage1;
        receiving_stage2    <= receiving_stage1;
        if (addr_matched_stage1 && receiving_stage1) begin
            if (bit_count_stage2 < 4'd8) begin
                data_stage2[7-bit_count_stage2] <= sda_sync;
                bit_count_stage2 <= bit_count_stage2 + 1'b1;
                data_latched <= 1'b0;
            end else if (bit_count_stage2 == 4'd8) begin
                // Data byte received, latch data
                data_latched <= 1'b1;
                bit_count_stage2 <= 4'd0;
            end
        end else begin
            bit_count_stage2 <= 4'd0;
            data_latched     <= 1'b0;
        end
        if (stop_condition) begin
            receiving_stage2 <= 1'b0;
        end
    end
end

// ============================================================================
// Output Data Register Stage and Data Valid Flag
// ============================================================================
always @(posedge scl_sync or negedge rst_n) begin
    if (!rst_n) begin
        data_received   <= 8'd0;
        data_valid_reg  <= 1'b0;
    end else begin
        if (data_latched) begin
            data_received  <= data_stage2;
            data_valid_reg <= 1'b1;
        end else if (stop_condition) begin
            data_valid_reg <= 1'b0;
        end
    end
end

assign data_valid = data_valid_reg;

endmodule

// ============================================================================
// Reusable 3-stage synchronizer module
// ============================================================================
module sync_3stage #(
    parameter SYNC_WIDTH = 1
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire [SYNC_WIDTH-1:0] async_in,
    output wire [SYNC_WIDTH-1:0] sync_out,
    output wire [SYNC_WIDTH-1:0] sync_out_prev
);

reg [SYNC_WIDTH-1:0] sync_ff0, sync_ff1, sync_ff2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sync_ff0 <= {SYNC_WIDTH{1'b0}};
        sync_ff1 <= {SYNC_WIDTH{1'b0}};
        sync_ff2 <= {SYNC_WIDTH{1'b0}};
    end else begin
        sync_ff0 <= async_in;
        sync_ff1 <= sync_ff0;
        sync_ff2 <= sync_ff1;
    end
end

assign sync_out      = sync_ff1;
assign sync_out_prev = sync_ff2;

endmodule