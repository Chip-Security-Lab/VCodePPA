//SystemVerilog
module MuxArbiter #(parameter W=8) (
    input clk,
    input rst_n,
    input [3:0] req,
    input [3:0][W-1:0] data,
    output reg [W-1:0] grant_data,
    output reg [3:0] grant
);

// Pipeline stage 1: Request processing
reg [3:0] req_stage1;
reg [3:0][W-1:0] data_stage1;
reg valid_stage1;

// Pipeline stage 2: Priority resolution
reg [3:0] req_stage2;
reg [3:0][W-1:0] data_stage2;
reg valid_stage2;
reg [3:0] grant_stage2;
reg [W-1:0] grant_data_stage2;

// Pipeline stage 1 logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req_stage1 <= 4'b0;
        data_stage1 <= 0;
        valid_stage1 <= 1'b0;
    end else begin
        req_stage1 <= req;
        data_stage1 <= data;
        valid_stage1 <= |req;
    end
end

// Pipeline stage 2 logic using optimized comparison
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req_stage2 <= 4'b0;
        data_stage2 <= 0;
        valid_stage2 <= 1'b0;
        grant_stage2 <= 4'b0;
        grant_data_stage2 <= 0;
    end else begin
        req_stage2 <= req_stage1;
        data_stage2 <= data_stage1;
        valid_stage2 <= valid_stage1;

        // Optimized comparison logic
        case (req_stage1)
            4'b0001: begin
                grant_stage2 <= 4'b0001;
                grant_data_stage2 <= data_stage1[0];
            end
            4'b0010: begin
                grant_stage2 <= 4'b0010;
                grant_data_stage2 <= data_stage1[1];
            end
            4'b0100: begin
                grant_stage2 <= 4'b0100;
                grant_data_stage2 <= data_stage1[2];
            end
            4'b1000: begin
                grant_stage2 <= 4'b1000;
                grant_data_stage2 <= data_stage1[3];
            end
            default: begin
                grant_stage2 <= 4'b0000;
                grant_data_stage2 <= 0;
            end
        endcase
    end
end

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        grant <= 4'b0;
        grant_data <= 0;
    end else begin
        grant <= grant_stage2;
        grant_data <= grant_data_stage2;
    end
end

endmodule