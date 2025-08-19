module tdp_ram_arbiter #(
    parameter DW = 28,
    parameter AW = 7
)(
    input clk,
    input arb_mode, // 0: PortA优先, 1: Round-Robin
    // Port A
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output reg [DW-1:0] a_dout,
    input a_we, a_re,
    // Port B
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output reg [DW-1:0] b_dout,
    input b_we, b_re
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg arb_flag;

always @(posedge clk) begin
    if (a_we & b_we) begin // 写冲突
        case(arb_mode)
            0: begin // PortA优先
                mem[a_addr] <= a_din;
                mem[b_addr] <= a_din; // 写相同数据
            end
            1: begin // 交替处理
                if (arb_flag) begin
                    mem[a_addr] <= a_din;
                    arb_flag <= 0;
                end else begin
                    mem[b_addr] <= b_din;
                    arb_flag <= 1;
                end
            end
        endcase
    end else begin
        if (a_we) mem[a_addr] <= a_din;
        if (b_we) mem[b_addr] <= b_din;
    end
    
    a_dout <= (a_re && !(b_re && arb_flag)) ? mem[a_addr] : 'hz;
    b_dout <= (b_re && !(a_re && !arb_flag)) ? mem[b_addr] : 'hz;
end
endmodule
