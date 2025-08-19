//SystemVerilog
module gray_queue #(parameter DW=8) (
    input clk,
    input rst,
    input en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);
    reg [DW:0] queue [0:1];
    wire [DW:0] gray_in;
    wire parity_wire;
    reg [1:0] ctrl_state;
    integer i;

    // 奇偶校验简化为归约异或
    assign parity_wire = ^din;
    assign gray_in = {din, parity_wire};

    // ctrl_state: [1] = rst, [0] = en
    always @(*) begin
        ctrl_state = {rst, en};
    end

    always @(posedge clk) begin
        case (ctrl_state)
            2'b10: begin // rst = 1
                queue[0] <= { (DW+1){1'b0} };
                queue[1] <= { (DW+1){1'b0} };
                dout <= { DW{1'b0} };
                error <= 1'b0;
            end
            2'b01: begin // rst = 0, en = 1
                queue[0] <= gray_in;
                queue[1] <= queue[0];
                dout <= queue[1][DW:1];
                error <= (^queue[1][DW:1]) ^ queue[1][0];
            end
            2'b00, // rst = 0, en = 0
            2'b11: ; // rst = 1, en = 1 (reset dominates)
        endcase
    end
endmodule