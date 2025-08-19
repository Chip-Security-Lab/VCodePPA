//SystemVerilog
module PriorityRecovery #(parameter WIDTH=8, SOURCES=4) (
    input clk,
    input [SOURCES-1:0] valid,
    input [WIDTH*SOURCES-1:0] data_bus,
    output reg [WIDTH-1:0] selected_data
);
    // Individual data buses for better timing
    wire [WIDTH-1:0] data_buses [SOURCES-1:0];
    
    // Split the data bus for individual access
    genvar i;
    generate
        for (i = 0; i < SOURCES; i = i + 1) begin : data_split
            assign data_buses[i] = data_bus[WIDTH*i +: WIDTH];
        end
    endgenerate
    
    // Pre-register individual data channels
    reg [WIDTH-1:0] data_reg [SOURCES-1:0];
    reg [SOURCES-1:0] valid_reg;
    
    // Register inputs (moved closer to inputs)
    always @(posedge clk) begin
        valid_reg <= valid;
        for (int j = 0; j < SOURCES; j = j + 1) begin
            data_reg[j] <= data_buses[j];
        end
    end
    
    // Priority selection with registered inputs
    // Combinational logic is now after the registers
    always @(posedge clk) begin
        if (valid_reg[3])
            selected_data <= data_reg[3];
        else if (valid_reg[2])
            selected_data <= data_reg[2];
        else if (valid_reg[1])
            selected_data <= data_reg[1];
        else if (valid_reg[0])
            selected_data <= data_reg[0];
        else
            selected_data <= {WIDTH{1'b0}};
    end
endmodule