//SystemVerilog
// Top-level module
module shadow_reg_mask #(
    parameter DW = 32
)(
    input                clk,
    input                en,
    input      [DW-1:0]  data_in,
    input      [DW-1:0]  mask,
    output     [DW-1:0]  data_out
);
    // Internal signals
    wire [DW-1:0] shadow_reg_value;
    
    // Submodule instantiations
    shadow_data_processor #(
        .DW(DW)
    ) data_processor_inst (
        .clk          (clk),
        .en           (en),
        .data_in      (data_in),
        .mask         (mask),
        .shadow_reg   (shadow_reg_value)
    );
    
    shadow_output_controller #(
        .DW(DW)
    ) output_controller_inst (
        .clk          (clk),
        .shadow_reg   (shadow_reg_value),
        .data_out     (data_out)
    );
    
endmodule

// Submodule for data processing and masking
module shadow_data_processor #(
    parameter DW = 32
)(
    input                clk,
    input                en,
    input      [DW-1:0]  data_in,
    input      [DW-1:0]  mask,
    output reg [DW-1:0]  shadow_reg
);
    // Masked data calculation and register update
    always @(posedge clk) begin
        if(en) begin
            shadow_reg <= (shadow_reg & ~mask) | (data_in & mask);
        end
    end
endmodule

// Submodule for output control
module shadow_output_controller #(
    parameter DW = 32
)(
    input                clk,
    input      [DW-1:0]  shadow_reg,
    output reg [DW-1:0]  data_out
);
    // Register shadow data to output
    always @(posedge clk) begin
        data_out <= shadow_reg;
    end
endmodule