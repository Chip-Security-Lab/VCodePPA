//SystemVerilog
module error_detect_decoder (
    input [3:0] addr,
    output reg [7:0] select,
    output reg error
);

    // 地址范围检查子模块
    wire addr_valid;
    address_validator addr_validator_inst (
        .addr(addr),
        .valid(addr_valid)
    );

    // 选择信号生成子模块
    wire [7:0] select_temp;
    select_generator select_gen_inst (
        .addr(addr),
        .select(select_temp)
    );

    // 错误检测和输出控制
    always @(*) begin
        error = ~addr_valid;
        select = addr_valid ? select_temp : 8'h00;
    end

endmodule

module address_validator (
    input [3:0] addr,
    output reg valid
);
    always @(*) begin
        valid = (addr < 4'h8);
    end
endmodule

module select_generator (
    input [3:0] addr,
    output reg [7:0] select
);
    always @(*) begin
        case(addr)
            4'h0: select = 8'b00000001;
            4'h1: select = 8'b00000010;
            4'h2: select = 8'b00000100;
            4'h3: select = 8'b00001000;
            4'h4: select = 8'b00010000;
            4'h5: select = 8'b00100000;
            4'h6: select = 8'b01000000;
            4'h7: select = 8'b10000000;
            default: select = 8'b00000000;
        endcase
    end
endmodule