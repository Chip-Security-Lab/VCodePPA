module i2c_multi_master #(
    parameter ARB_TIMEOUT = 1000  // Arbitration timeout cycles
)(
    input clk,
    input rst,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg bus_busy,
    inout sda,
    inout scl
);
// Using conflict detection + timeout mechanism
reg sda_prev, scl_prev;
reg [15:0] timeout_cnt;
reg arbitration_lost;
reg tx_oen;  // Added missing signal
reg scl_oen; // Added missing signal
reg [2:0] bit_cnt; // Added bit counter

always @(posedge clk) begin
    if (rst) begin
        bus_busy <= 0;
        arbitration_lost <= 0;
        sda_prev <= 1'b1;
        scl_prev <= 1'b1;
        timeout_cnt <= 16'h0000;
        tx_oen <= 1'b1;
        scl_oen <= 1'b1;
        bit_cnt <= 3'b000;
    end else begin
        // Arbitration detection logic
        sda_prev <= sda;
        scl_prev <= scl;
        
        if (sda != sda_prev && bus_busy) begin
            arbitration_lost <= 1;
        end
        
        // Timeout counter
        if (bus_busy) begin
            timeout_cnt <= timeout_cnt + 1;
            if (timeout_cnt >= ARB_TIMEOUT) begin
                bus_busy <= 0;
                tx_oen <= 1'b1;
                scl_oen <= 1'b1;
            end
        end
    end
end

// Tri-state control with bus monitoring
assign sda = (tx_oen) ? tx_data[bit_cnt] : 1'bz;
assign scl = (scl_oen) ? 1'b0 : 1'bz;
endmodule