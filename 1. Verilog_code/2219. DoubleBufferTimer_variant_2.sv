//SystemVerilog
module DoubleBufferTimer #(parameter DW=8) (
    input wire clk, rst_n,
    input wire [DW-1:0] next_period,
    output reg [DW-1:0] current
);
    reg [DW-1:0] buffer;
    reg current_zero_reg;
    wire current_zero;
    reg [DW-1:0] next_current;
    
    // Pre-calculate the zero condition and register it
    assign current_zero = (current == {DW{1'b0}});
    
    // Pre-calculate the next value of current
    always @(*) begin
        if (current_zero_reg)
            next_current = buffer;
        else
            next_current = current - {{(DW-1){1'b0}}, 1'b1};
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            current <= {DW{1'b0}};
            buffer <= {DW{1'b0}};
            current_zero_reg <= 1'b1;
        end
        else begin
            current <= next_current;
            current_zero_reg <= current_zero;
            
            if (current_zero_reg)
                buffer <= next_period;
        end
    end
endmodule