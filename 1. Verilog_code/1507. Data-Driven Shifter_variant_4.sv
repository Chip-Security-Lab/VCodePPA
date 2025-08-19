//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog standard
module data_driven_shifter #(parameter WIDTH = 8) (
    input wire clk, rst,
    input wire data_valid,
    input wire serial_in,
    output wire [WIDTH-1:0] parallel_out
);
    // Pipeline stage registers with increased pipeline depth
    reg [WIDTH-1:0] shift_data_stage1;
    reg [(WIDTH/2)-1:0] shift_data_stage2a;
    reg [(WIDTH/2)-1:0] shift_data_stage2b;
    reg [(WIDTH/4)-1:0] shift_data_stage3a;
    reg [(WIDTH/4)-1:0] shift_data_stage3b;
    reg [(WIDTH/4)-1:0] shift_data_stage3c;
    reg [(WIDTH/4)-1:0] shift_data_stage3d;
    reg [WIDTH-1:0] shift_data_stage4;
    reg [WIDTH-1:0] shift_data_stage5;
    
    // Valid signal propagation through increased pipeline stages
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Stage 1: Input capture and first shift operation
    always @(posedge clk) begin
        if (rst) begin
            shift_data_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else if (data_valid) begin
            shift_data_stage1 <= {shift_data_stage1[WIDTH-2:0], serial_in};
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Split processing into two parallel paths
    always @(posedge clk) begin
        if (rst) begin
            shift_data_stage2a <= 0;
            shift_data_stage2b <= 0;
            valid_stage2 <= 0;
        end
        else if (valid_stage1) begin
            shift_data_stage2a <= shift_data_stage1[WIDTH-1:WIDTH/2];
            shift_data_stage2b <= shift_data_stage1[(WIDTH/2)-1:0];
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Further split for finer-grained pipelining
    always @(posedge clk) begin
        if (rst) begin
            shift_data_stage3a <= 0;
            shift_data_stage3b <= 0;
            shift_data_stage3c <= 0;
            shift_data_stage3d <= 0;
            valid_stage3 <= 0;
        end
        else if (valid_stage2) begin
            shift_data_stage3a <= shift_data_stage2a[(WIDTH/2)-1:(WIDTH/4)];
            shift_data_stage3b <= shift_data_stage2a[(WIDTH/4)-1:0];
            shift_data_stage3c <= shift_data_stage2b[(WIDTH/2)-1:(WIDTH/4)];
            shift_data_stage3d <= shift_data_stage2b[(WIDTH/4)-1:0];
            valid_stage3 <= valid_stage2;
        end
        else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // Stage 4: Recombine the processed data
    always @(posedge clk) begin
        if (rst) begin
            shift_data_stage4 <= 0;
            valid_stage4 <= 0;
        end
        else if (valid_stage3) begin
            shift_data_stage4 <= {shift_data_stage3a, shift_data_stage3b, 
                                 shift_data_stage3c, shift_data_stage3d};
            valid_stage4 <= valid_stage3;
        end
        else begin
            valid_stage4 <= 1'b0;
        end
    end
    
    // Stage 5: Final output stage
    always @(posedge clk) begin
        if (rst) begin
            shift_data_stage5 <= 0;
        end
        else if (valid_stage4) begin
            shift_data_stage5 <= shift_data_stage4;
        end
    end
    
    // Output assignment
    assign parallel_out = shift_data_stage5;
    
endmodule