//SystemVerilog
module MuxArbiter #(parameter W=8) (
    input clk,
    input rst_n,
    input [3:0] req,
    input [3:0][W-1:0] data,
    output reg [W-1:0] grant_data,
    output reg [3:0] grant
);

    // Pipeline stage 1 signals
    reg [3:0] req_stage1;
    reg [3:0][W-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 signals
    reg [3:0] grant_stage2;
    reg [W-1:0] grant_data_stage2;
    reg valid_stage2;

    // Stage 1: Input sampling and validation
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

    // Stage 2: Optimized arbitration logic using priority encoder
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_stage2 <= 4'b0;
            grant_data_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            case (1'b1)
                req_stage1[0]: begin
                    grant_stage2 <= 4'b0001;
                    grant_data_stage2 <= data_stage1[0];
                end
                req_stage1[1]: begin
                    grant_stage2 <= 4'b0010;
                    grant_data_stage2 <= data_stage1[1];
                end
                req_stage1[2]: begin
                    grant_stage2 <= 4'b0100;
                    grant_data_stage2 <= data_stage1[2];
                end
                req_stage1[3]: begin
                    grant_stage2 <= 4'b1000;
                    grant_data_stage2 <= data_stage1[3];
                end
                default: begin
                    grant_stage2 <= 4'b0;
                    grant_data_stage2 <= 0;
                end
            endcase
            valid_stage2 <= 1'b1;
        end else begin
            grant_stage2 <= 4'b0;
            grant_data_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 4'b0;
            grant_data <= 0;
        end else if (valid_stage2) begin
            grant <= grant_stage2;
            grant_data <= grant_data_stage2;
        end else begin
            grant <= 4'b0;
            grant_data <= 0;
        end
    end

endmodule