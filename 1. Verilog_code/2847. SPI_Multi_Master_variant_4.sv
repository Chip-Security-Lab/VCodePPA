//SystemVerilog
module SPI_Multi_Master #(
    parameter MASTERS = 3
)(
    input clk, rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] gnt,
    // Shared bus
    inout sclk, mosi, miso,
    output reg [MASTERS-1:0] cs_n
);

reg [1:0] curr_state;
reg [4:0] timeout_counter;
reg [MASTERS-1:0] last_grant;

// Define signals for bus driving
wire [MASTERS-1:0] master_sclk;
wire [MASTERS-1:0] master_mosi;
wire slave_miso;

localparam IDLE = 2'd0, ARBITRATION = 2'd1, TRANSFER = 2'd2;

// Conflict detection logic
wire bus_busy = |(~cs_n);
wire collision = (|(gnt & req)) && bus_busy;

// Priority arbiter
always @(*) begin
    casex(req)
        3'b??1: gnt = 3'b001;
        3'b?10: gnt = 3'b010;
        3'b100: gnt = 3'b100;
        default: gnt = 3'b000;
    endcase
end

// 条件反相减法器算法实现5位加法减法功能
function [4:0] cond_invert_subtractor_5bit;
    input [4:0] operand_a;
    input [4:0] operand_b;
    input operation_sel; // 0: add, 1: subtract
    reg [4:0] operand_b_invert;
    reg [5:0] sum_with_carry;
    begin
        operand_b_invert = operand_b ^ {5{operation_sel}}; // 条件反相
        sum_with_carry = {1'b0, operand_a} + {1'b0, operand_b_invert} + operation_sel;
        cond_invert_subtractor_5bit = sum_with_carry[4:0];
    end
endfunction

// timeout_counter加法器使用条件反相减法器算法
wire [4:0] next_timeout_counter;
assign next_timeout_counter = cond_invert_subtractor_5bit(timeout_counter, 5'b00001, 1'b0); // 加1

// timeout_counter减法比较使用条件反相减法器算法
wire [4:0] compare_result;
assign compare_result = cond_invert_subtractor_5bit(timeout_counter, 5'd10, 1'b1); // timeout_counter - 10

wire timeout_counter_gt_10;
assign timeout_counter_gt_10 = ~compare_result[4]; // 超过10为正

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= IDLE;
        timeout_counter <= 5'b00000;
        last_grant <= {MASTERS{1'b0}};
        cs_n <= {MASTERS{1'b1}};
    end else begin
        case(curr_state)
        IDLE: begin
            if(|req && !bus_busy) begin
                curr_state <= ARBITRATION;
                last_grant <= gnt;
                timeout_counter <= 5'b00000;
            end
        end
        ARBITRATION: begin
            timeout_counter <= next_timeout_counter;
            if(timeout_counter_gt_10)
                curr_state <= TRANSFER;
        end
        TRANSFER: begin
            if(cs_n == {MASTERS{1'b1}})
                curr_state <= IDLE;
        end
        default: curr_state <= IDLE;
        endcase
    end
end

// Simplified bus driving logic
assign sclk = gnt[0] ? master_sclk[0] :
              gnt[1] ? master_sclk[1] :
              gnt[2] ? master_sclk[2] : 1'bz;
              
assign mosi = gnt[0] ? master_mosi[0] :
              gnt[1] ? master_mosi[1] :
              gnt[2] ? master_mosi[2] : 1'bz;
              
// Placeholder assignments for simulation
assign master_sclk = {MASTERS{1'b0}};
assign master_mosi = {MASTERS{1'b0}};
assign slave_miso = miso;

// Chip select is active low when granted
always @(*) begin
    cs_n = ~gnt;
end

endmodule