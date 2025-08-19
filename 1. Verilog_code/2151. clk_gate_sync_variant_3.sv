//SystemVerilog
module clk_gate_sync #(parameter WIDTH=4) (
    input clk, en,
    output reg [WIDTH-1:0] out
);
    // Pipeline registers
    reg en_reg1, en_reg2;
    reg [WIDTH-1:0] out_reg;
    reg [WIDTH-1:0] incr_value;
    reg [WIDTH-1:0] next_out;
    
    // Separate clock enable signal registration into two stages
    // to reduce fanout and improve timing
    always @(posedge clk) begin
        en_reg1 <= en;
        en_reg2 <= en_reg1;
    end
    
    // Pipeline stage 1: Register current output value
    always @(posedge clk) begin
        out_reg <= out;
    end
    
    // Pipeline stage 2: Pre-compute increment value with registered output
    always @(posedge clk) begin
        incr_value <= out_reg + 1;
    end
    
    // Pipeline stage 3: Select based on registered enable signal
    always @(posedge clk) begin
        next_out <= en_reg2 ? incr_value : out_reg;
    end
    
    // Final output register update stage
    always @(posedge clk) begin
        out <= next_out;
    end
endmodule