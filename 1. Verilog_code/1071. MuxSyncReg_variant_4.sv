//SystemVerilog
module MuxSyncReg #(parameter DW=8, AW=3) (
    input wire clk, 
    input wire rst_n, 
    input wire [AW-1:0] sel,
    input wire [2**AW*DW-1:0] data_in,
    output reg [DW-1:0] data_out
);

    // Stage 1: Combinational MUX - select data word directly
    wire [DW-1:0] selected_data;
    assign selected_data = data_in[sel*DW +: DW];

    // Stage 2: Register selected data
    reg [DW-1:0] data_stage;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_stage <= {DW{1'b0}};
        else
            data_stage <= selected_data;
    end

    // Stage 3: Output register for final data_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DW{1'b0}};
        else
            data_out <= data_stage;
    end

endmodule