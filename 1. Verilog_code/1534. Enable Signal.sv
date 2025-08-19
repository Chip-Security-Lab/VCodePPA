module enabled_shadow_reg #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_input,
    input wire shadow_capture,
    output reg [DATA_WIDTH-1:0] shadow_output
);
    // Main data register
    reg [DATA_WIDTH-1:0] data_reg;
    
    // Main register logic with enable
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            data_reg <= {DATA_WIDTH{1'b0}};
        else if (enable)
            data_reg <= data_input;
    end
    
    // Shadow register capture logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            shadow_output <= {DATA_WIDTH{1'b0}};
        else if (shadow_capture && enable)
            shadow_output <= data_reg;
    end
endmodule