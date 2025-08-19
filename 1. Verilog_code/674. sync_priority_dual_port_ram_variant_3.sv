//SystemVerilog
module sync_priority_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg read_first_stage1;
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg valid_stage1, valid_stage2;

    // 条件反相减法器相关信号
    reg [DATA_WIDTH-1:0] sub_result_a, sub_result_b;
    reg [DATA_WIDTH-1:0] inverted_b_a, inverted_b_b;
    reg carry_in_a, carry_in_b;
    reg [DATA_WIDTH-1:0] temp_result_a, temp_result_b;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            read_first_stage1 <= 0;
            valid_stage1 <= 0;
            sub_result_a <= 0;
            sub_result_b <= 0;
            inverted_b_a <= 0;
            inverted_b_b <= 0;
            carry_in_a <= 0;
            carry_in_b <= 0;
            temp_result_a <= 0;
            temp_result_b <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            read_first_stage1 <= read_first;
            valid_stage1 <= 1;

            // 条件反相减法器实现
            inverted_b_a = ~din_b_stage1;
            inverted_b_b = ~din_a_stage1;
            carry_in_a = 1'b1;
            carry_in_b = 1'b1;
            temp_result_a = din_a_stage1 + inverted_b_a + carry_in_a;
            temp_result_b = din_b_stage1 + inverted_b_b + carry_in_b;
            sub_result_a = temp_result_a;
            sub_result_b = temp_result_b;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            if (read_first_stage1) begin
                dout_a <= ram[addr_a_stage1];
                dout_b <= ram[addr_b_stage1];
                if (we_a_stage1) ram[addr_a_stage1] <= sub_result_a;
                if (we_b_stage1) ram[addr_b_stage1] <= sub_result_b;
            end else begin
                if (we_a_stage1) ram[addr_a_stage1] <= sub_result_a;
                if (we_b_stage1) ram[addr_b_stage1] <= sub_result_b;
                dout_a <= ram[addr_a_stage1];
                dout_b <= ram[addr_b_stage1];
            end
            valid_stage2 <= 1;
        end else begin
            valid_stage2 <= 0;
        end
    end
endmodule