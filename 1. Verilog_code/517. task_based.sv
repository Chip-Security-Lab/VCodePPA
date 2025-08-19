module task_based(
    input [3:0] in,
    output reg [1:0] out
);
    task automatic process;
        input [3:0] i;
        output [1:0] o;
        begin
            o = {i[3], ^i[2:0]};
        end
    endtask
    
    always @(*) begin
        process(in, out);
    end
endmodule