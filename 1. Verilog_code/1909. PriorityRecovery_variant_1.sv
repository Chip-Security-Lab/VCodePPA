//SystemVerilog
module PriorityRecovery #(parameter WIDTH=8, SOURCES=4) (
    input clk,
    input [SOURCES-1:0] valid,
    input [WIDTH*SOURCES-1:0] data_bus,
    output reg [WIDTH-1:0] selected_data
);
    // Intermediate signals for data paths
    wire [WIDTH-1:0] data_paths [0:SOURCES-1];
    wire [WIDTH-1:0] default_path;
    reg [SOURCES:0] priority_select; // One-hot encoding with additional bit for default case
    
    // Extract individual data paths
    generate
        genvar i;
        for (i = 0; i < SOURCES; i = i + 1) begin : gen_data_paths
            assign data_paths[i] = data_bus[WIDTH*i +: WIDTH];
        end
    endgenerate
    
    // Default path when no valid inputs
    assign default_path = {WIDTH{1'b0}};
    
    // Priority encoder - separate always block for priority logic
    always @(posedge clk) begin
        priority_select <= {SOURCES+1{1'b0}}; // Default all zeros
        
        if (valid[SOURCES-1])
            priority_select[SOURCES-1] <= 1'b1;
        else if (valid[SOURCES-2])
            priority_select[SOURCES-2] <= 1'b1;
        else if (valid[SOURCES-3])
            priority_select[SOURCES-3] <= 1'b1;
        else if (valid[SOURCES-4])
            priority_select[SOURCES-4] <= 1'b1;
        else
            priority_select[SOURCES] <= 1'b1; // Default case
    end
    
    // Data selection - separate always block for output assignment
    always @(posedge clk) begin
        if (priority_select[SOURCES-1])
            selected_data <= data_paths[SOURCES-1];
        else if (priority_select[SOURCES-2])
            selected_data <= data_paths[SOURCES-2];
        else if (priority_select[SOURCES-3])
            selected_data <= data_paths[SOURCES-3];
        else if (priority_select[SOURCES-4])
            selected_data <= data_paths[SOURCES-4];
        else
            selected_data <= default_path;
    end
endmodule