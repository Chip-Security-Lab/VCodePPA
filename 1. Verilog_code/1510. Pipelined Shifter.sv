module pipelined_shifter #(parameter STAGES = 4, WIDTH = 8) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] pipe [0:STAGES-1];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1)
                pipe[i] <= 0;
        end else begin
            pipe[0] <= data_in;
            for (i = 1; i < STAGES; i = i + 1)
                pipe[i] <= pipe[i-1];
        end
    end
    
    assign data_out = pipe[STAGES-1];
endmodule