//SystemVerilog
module int_ctrl_edge #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] async_intr,
    output reg [WIDTH-1:0] synced_intr
);

    // Stage 1 - Input synchronization
    reg [WIDTH-1:0] intr_stage1;
    reg [WIDTH-1:0] valid_stage1;
    
    // Stage 2 - Edge detection
    reg [WIDTH-1:0] intr_stage2;
    reg [WIDTH-1:0] prev_intr_stage2;
    reg valid_stage2;
    
    // Stage 3 - Output generation
    reg [WIDTH-1:0] edge_detected_stage3;
    reg valid_stage3;
    
    // Stage 1: Input synchronization and validation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= {WIDTH{1'b0}};
        end else begin
            intr_stage1 <= async_intr;
            valid_stage1 <= {WIDTH{1'b1}}; // Mark data as valid
        end
    end
    
    // Stage 2: Store previous value and prepare for edge detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_stage2 <= {WIDTH{1'b0}};
            prev_intr_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            intr_stage2 <= intr_stage1;
            prev_intr_stage2 <= intr_stage2;
            valid_stage2 <= |valid_stage1; // Propagate valid signal
        end
    end
    
    // Stage 3: Perform edge detection and generate output - flattened structure
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_detected_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            synced_intr <= {WIDTH{1'b0}};
        end else if (valid_stage2) begin
            edge_detected_stage3 <= intr_stage2 & ~prev_intr_stage2;
            valid_stage3 <= 1'b1;
            synced_intr <= valid_stage3 ? edge_detected_stage3 : {WIDTH{1'b0}};
        end else begin
            edge_detected_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            synced_intr <= {WIDTH{1'b0}};
        end
    end

endmodule