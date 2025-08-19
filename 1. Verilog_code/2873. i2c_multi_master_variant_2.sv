//SystemVerilog
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
reg tx_oen;  
reg scl_oen; 
reg [2:0] bit_cnt;
wire sda_in, scl_in;
reg [7:0] tx_data_reg;

// 曼彻斯特进位链加法器相关信号
wire [15:0] manchester_sum;
wire [15:0] carry_gen;
wire [15:0] carry_prop;
wire [15:0] carry_chain;

// Sample inputs first to reduce input-to-register delay
assign sda_in = sda;
assign scl_in = scl;

// 曼彻斯特进位链加法器实现
// 生成和传播信号
assign carry_gen = {timeout_cnt[14:0], 1'b0};  // Generate signals
assign carry_prop = timeout_cnt;               // Propagate signals

// 曼彻斯特进位链计算
assign carry_chain[0] = carry_gen[0];
genvar i;
generate
    for (i = 1; i < 16; i = i + 1) begin : manchester_carry_chain
        assign carry_chain[i] = carry_gen[i] | (carry_prop[i] & carry_chain[i-1]);
    end
endgenerate

// 计算和
assign manchester_sum[0] = timeout_cnt[0] ^ 1'b1;
generate
    for (i = 1; i < 16; i = i + 1) begin : manchester_sum_calc
        assign manchester_sum[i] = timeout_cnt[i] ^ carry_chain[i-1];
    end
endgenerate

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
        tx_data_reg <= 8'h00;
    end else begin
        // Register input data to improve timing
        tx_data_reg <= tx_data;
        
        // Moved registers forward - sample inputs directly
        sda_prev <= sda_in;
        scl_prev <= scl_in;
        
        // Arbitration detection logic moved after input sampling
        if (sda_in != sda_prev && bus_busy) begin
            arbitration_lost <= 1;
        end
        
        // Timeout counter using Manchester Carry Chain adder
        if (bus_busy) begin
            timeout_cnt <= manchester_sum;
            if (timeout_cnt >= ARB_TIMEOUT) begin
                bus_busy <= 0;
                tx_oen <= 1'b1;
                scl_oen <= 1'b1;
            end
        end
    end
end

// Tri-state control with bus monitoring
// Using registered tx_data to improve timing
assign sda = (tx_oen) ? tx_data_reg[bit_cnt] : 1'bz;
assign scl = (scl_oen) ? 1'b0 : 1'bz;
endmodule