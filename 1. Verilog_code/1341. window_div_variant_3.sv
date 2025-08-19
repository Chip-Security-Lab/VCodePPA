//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: window_div.v
// Description: Top level module that generates a windowed clock output
// based on counter values between L and H.
///////////////////////////////////////////////////////////////////////////////

module window_div #(
    parameter L = 5,
    parameter H = 12
) (
    input wire clk,
    input wire rst_n,
    output wire clk_out
);
    
    // Internal signals
    wire [7:0] counter_value;
    wire window_enable;
    
    // Counter submodule instance
    counter_module #(
        .WIDTH(8)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count(counter_value)
    );
    
    // Window detection submodule instance
    window_detector #(
        .LOW_THRESHOLD(L),
        .HIGH_THRESHOLD(H)
    ) detector_inst (
        .counter_value(counter_value),
        .window_active(window_enable)
    );
    
    // Output register submodule instance
    output_register output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable_in(window_enable),
        .reg_out(clk_out)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Counter module
///////////////////////////////////////////////////////////////////////////////

module counter_module #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] count
);
    
    always @(posedge clk) begin
        if (!rst_n) 
            count <= {WIDTH{1'b0}};
        else
            count <= count + 1'b1;
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Window detector module
///////////////////////////////////////////////////////////////////////////////

module window_detector #(
    parameter LOW_THRESHOLD = 5,
    parameter HIGH_THRESHOLD = 12
) (
    input wire [7:0] counter_value,
    output wire window_active
);
    
    // Determine if counter is within the specified window
    assign window_active = (counter_value >= LOW_THRESHOLD) && 
                           (counter_value <= HIGH_THRESHOLD);
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Output register module
///////////////////////////////////////////////////////////////////////////////

module output_register (
    input wire clk,
    input wire rst_n,
    input wire enable_in,
    output reg reg_out
);
    
    always @(posedge clk) begin
        if (!rst_n)
            reg_out <= 1'b0;
        else
            reg_out <= enable_in;
    end
    
endmodule