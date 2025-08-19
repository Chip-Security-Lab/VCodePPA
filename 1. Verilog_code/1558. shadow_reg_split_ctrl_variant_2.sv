//SystemVerilog
module shadow_reg_split_ctrl #(parameter DW=12) (
    input clk, load, update,
    input [DW-1:0] datain,
    output [DW-1:0] dataout
);
    // Internal connections between submodules
    wire [DW-1:0] shadow_data;
    
    // Shadow register submodule instantiation
    shadow_register #(
        .DW(DW)
    ) shadow_reg_inst (
        .clk(clk),
        .load(load),
        .datain(datain),
        .shadow_data(shadow_data)
    );
    
    // Output register submodule instantiation
    output_register #(
        .DW(DW)
    ) output_reg_inst (
        .clk(clk),
        .update(update),
        .shadow_data(shadow_data),
        .dataout(dataout)
    );
    
endmodule

// Shadow register submodule - responsible for capturing input data
module shadow_register #(parameter DW=12) (
    input clk,
    input load,
    input [DW-1:0] datain,
    output reg [DW-1:0] shadow_data
);
    always @(posedge clk) begin
        if(load) shadow_data <= datain;
    end
endmodule

// Output register submodule - responsible for updating output when requested
module output_register #(parameter DW=12) (
    input clk,
    input update,
    input [DW-1:0] shadow_data,
    output reg [DW-1:0] dataout
);
    always @(posedge clk) begin
        if(update) dataout <= shadow_data;
    end
endmodule