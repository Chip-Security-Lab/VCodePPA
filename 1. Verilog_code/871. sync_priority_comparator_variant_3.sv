//SystemVerilog
module sync_priority_comparator #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out,
    output reg valid
);

    // Pipeline stage 1: Data input and initial processing
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Priority encoding
    reg [$clog2(WIDTH)-1:0] priority_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= |data_in;
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            priority_stage2 <= 0;
            
            for (int i = WIDTH-1; i >= 0; i--) begin
                if (data_stage1[i]) 
                    priority_stage2 <= i[$clog2(WIDTH)-1:0];
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            valid <= 0;
        end else begin
            priority_out <= priority_stage2;
            valid <= valid_stage2;
        end
    end

endmodule