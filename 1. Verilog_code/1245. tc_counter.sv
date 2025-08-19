module tc_counter #(parameter WIDTH = 8) (
    input wire clock, clear, enable,
    output reg [WIDTH-1:0] counter,
    output wire tc
);
    assign tc = &counter & enable;
    
    always @(posedge clock) begin
        if (clear)
            counter <= {WIDTH{1'b0}};
        else if (enable)
            counter <= counter + 1'b1;
    end
endmodule
