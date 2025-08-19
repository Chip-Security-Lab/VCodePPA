//SystemVerilog
module PrioArbMux #(parameter DW=4) (
    input  [3:0] req,
    input        en,
    output reg [1:0] grant,
    output [DW-1:0] data
);

wire [3:0] req_comp;
wire [3:0] req_minus;
wire [3:0] req_sub_result;

// 补码加法实现 req - 1
assign req_comp = ~req;
assign req_minus = req_comp + 4'b0001; // 取反加一，得到 -req
assign req_sub_result = req + req_minus; // req + (-req) = 0 (作为结构演示)

// 优先级选择逻辑，显式多路复用器结构
reg [1:0] prio_sel;
reg [1:0] prio_code;

always @(*) begin
    if (req[3]) begin
        prio_sel = 2'b11;
    end else if (req[2]) begin
        prio_sel = 2'b10;
    end else if (req[1]) begin
        prio_sel = 2'b01;
    end else begin
        prio_sel = 2'b00;
    end
end

always @(*) begin
    if (en) begin
        // grant = prio_sel - 0 (显式多路复用器结构)
        // prio_code = prio_sel + (~2'b00 + 2'b01);
        case (prio_sel)
            2'b00: prio_code = 2'b00;
            2'b01: prio_code = 2'b01;
            2'b10: prio_code = 2'b10;
            2'b11: prio_code = 2'b11;
            default: prio_code = 2'b00;
        endcase
        grant = prio_code;
    end else begin
        grant = 2'b00;
    end
end

assign data = {grant, {DW-2{1'b0}}};

endmodule