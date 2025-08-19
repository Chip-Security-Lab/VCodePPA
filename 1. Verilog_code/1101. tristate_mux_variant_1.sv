//SystemVerilog
module tristate_mux (
    input wire [7:0] source_a, 
    input wire [7:0] source_b, 
    input wire select,            
    input wire output_enable,     
    output wire [7:0] data_bus    
);

reg [7:0] internal_data_bus;
reg internal_drive_enable;

always @(*) begin
    if (output_enable && select) begin
        internal_data_bus = source_b;
        internal_drive_enable = 1'b1;
    end else if (output_enable && ~select) begin
        internal_data_bus = source_a;
        internal_drive_enable = 1'b1;
    end else if (~output_enable) begin
        internal_data_bus = 8'b0;
        internal_drive_enable = 1'b0;
    end else begin
        internal_data_bus = 8'b0;
        internal_drive_enable = 1'b0;
    end
end

assign data_bus = internal_drive_enable ? internal_data_bus : 8'bz;

endmodule