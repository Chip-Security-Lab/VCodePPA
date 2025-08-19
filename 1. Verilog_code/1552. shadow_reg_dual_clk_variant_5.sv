//SystemVerilog
// Top level module
module shadow_reg_dual_clk #(parameter DW=16) (
    input main_clk, shadow_clk,
    input load, 
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    wire [DW-1:0] stage1_to_stage2;
    wire load_stage1_to_stage2;

    // Main clock domain stage
    main_domain_stage #(.DW(DW)) main_stage (
        .clk(main_clk),
        .load(load),
        .din(din),
        .dout(stage1_to_stage2),
        .load_out(load_stage1_to_stage2)
    );

    // Shadow clock domain stage
    shadow_domain_stage #(.DW(DW)) shadow_stage (
        .clk(shadow_clk),
        .load_in(load_stage1_to_stage2),
        .din(stage1_to_stage2),
        .dout(dout)
    );

endmodule

// Main clock domain stage
module main_domain_stage #(parameter DW=16) (
    input clk,
    input load,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg load_out
);

    always @(posedge clk) begin
        load_out <= load;
        if(load_out) 
            dout <= din;
    end

endmodule

// Shadow clock domain stage
module shadow_domain_stage #(parameter DW=16) (
    input clk,
    input load_in,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] shadow_storage;

    always @(posedge clk) begin
        if(load_in)
            shadow_storage <= din;
        dout <= shadow_storage;
    end

endmodule