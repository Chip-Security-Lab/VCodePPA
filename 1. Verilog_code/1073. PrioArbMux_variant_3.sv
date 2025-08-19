//SystemVerilog
module PrioArbMux #(parameter DW=4) (
    input  [3:0] req,
    input        en,
    output reg [1:0] grant,
    output     [DW-1:0] data
);

reg [1:0] prio_sel;

always @* begin
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

always @* begin
    if (en) begin
        grant = prio_sel;
    end else begin
        grant = 2'b00;
    end
end

assign data = {grant, {DW-2{1'b0}}};

endmodule