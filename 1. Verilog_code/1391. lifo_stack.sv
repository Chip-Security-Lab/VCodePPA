module lifo_stack #(parameter DW=8, DEPTH=8) (
    input clk, rst_n,
    input push, pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [2:0] ptr=0;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) ptr <= 0;
        else case({push,pop})
            2'b10: if(!full) begin
                mem[ptr] <= din;
                ptr <= ptr + 1;
            end
            2'b01: if(!empty) ptr <= ptr - 1;
        endcase
    end
    assign dout = mem[ptr-1];
    assign full = (ptr == DEPTH);
    assign empty = (ptr == 0);
endmodule
