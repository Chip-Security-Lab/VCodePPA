//SystemVerilog
module ecc_regfile #(
    parameter DW = 32,
    parameter AW = 4
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output reg parity_err
);
    reg [DW:0] mem [0:(1<<AW)-1]; // 额外位存储校验位
    reg [DW:0] current;
    reg [DW:0] next_data;
    
    // 条件求和减法算法计算奇偶校验位
    function automatic bit calc_parity;
        input [DW-1:0] data;
        bit parity;
        bit carry;
        bit [7:0] temp_result;
        bit [7:0] byte_parity;
        integer i, j;
        begin
            parity = 0;
            // 每8位一组计算部分奇偶校验
            for (i = 0; i < DW; i = i + 8) begin
                byte_parity = 0;
                for (j = 0; j < 8 && (i+j) < DW; j = j + 1) begin
                    // 条件求和算法
                    carry = byte_parity[0] & data[i+j];
                    temp_result = byte_parity + data[i+j] + carry;
                    byte_parity = temp_result;
                end
                // 字节奇偶校验位异或
                parity = parity ^ (^byte_parity);
            end
            calc_parity = parity;
        end
    endfunction
    
    always @(*) begin
        next_data = {din, calc_parity(din)};
    end

    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < (1<<AW); i = i + 1) begin
                mem[i] <= {(DW+1){1'b0}};
            end
            parity_err <= 0;
            current <= 0;
        end else begin
            if (wr_en) begin
                mem[addr] <= next_data; // 使用条件求和计算的校验位
            end
            
            current <= mem[addr];
            // 使用条件求和法验证读取数据的完整性
            parity_err <= current[DW] ^ calc_parity(current[DW-1:0]);
        end
    end

    assign dout = current[DW-1:0];
endmodule