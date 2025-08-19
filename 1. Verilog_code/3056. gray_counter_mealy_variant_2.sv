//SystemVerilog
// Top level module
module gray_counter_mealy(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire up_down,
    output wire [3:0] gray_out
);
    wire [3:0] binary_count;
    
    binary_counter counter_inst(
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .up_down(up_down),
        .count(binary_count)
    );
    
    binary_to_gray converter_inst(
        .binary_in(binary_count),
        .gray_out(gray_out)
    );
endmodule

// Binary counter submodule with optimized structure
module binary_counter(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire up_down,
    output reg [3:0] count
);
    reg [3:0] next_count;
    
    // Reset and enable control
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            count <= 4'b0000;
    end
    
    // Count update logic
    always @(posedge clock) begin
        if (reset_n && enable)
            count <= next_count;
    end
    
    // Next count calculation
    always @(*) begin
        if (up_down)
            next_count = count - 1'b1;
        else
            next_count = count + 1'b1;
    end
endmodule

// Binary to Gray code converter submodule
module binary_to_gray(
    input wire [3:0] binary_in,
    output wire [3:0] gray_out
);
    assign gray_out = {binary_in[3], binary_in[3:1] ^ binary_in[2:0]};
endmodule