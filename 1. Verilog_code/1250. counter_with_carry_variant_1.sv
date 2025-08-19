//SystemVerilog
// Top-level module
module counter_with_carry (
    input wire clk,
    input wire rst_n,
    output wire [3:0] count,
    output wire cout
);
    // Internal signals for connecting submodules
    wire [3:0] counter_value;
    
    // Instantiate counter logic submodule
    counter_logic counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count(counter_value)
    );
    
    // Instantiate carry detection submodule
    carry_detector carry_inst (
        .count_value(counter_value),
        .carry_out(cout)
    );
    
    // Connect internal counter value to output
    assign count = counter_value;
    
endmodule

// Counter logic submodule - handles the counting functionality
module counter_logic (
    input wire clk,
    input wire rst_n,
    output reg [3:0] count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'b0000;
        else
            count <= count + 1'b1;
    end
endmodule

// Carry detector submodule - determines when counter reaches maximum value
module carry_detector (
    input wire [3:0] count_value,
    output wire carry_out
);
    // Generate carry when counter reaches maximum value (4'b1111)
    assign carry_out = (count_value == 4'b1111);
endmodule