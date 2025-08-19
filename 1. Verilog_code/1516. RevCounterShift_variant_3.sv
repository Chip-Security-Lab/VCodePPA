//SystemVerilog
module RevCounterShift #(parameter N=4) (
    input wire clk,
    input wire rst_n,
    input wire up_down,
    input wire load,
    input wire [N-1:0] preset,
    output reg [N-1:0] cnt,
    output reg valid_out
);

// Pipeline registers
reg [N-1:0] cnt_stage1;
reg [N-1:0] cnt_stage2;
reg [N-1:0] cnt_stage3;
reg valid_stage1;
reg valid_stage2;
reg valid_stage3;
reg up_down_reg;

// Stage 1: Load and direction selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_stage1 <= {N{1'b0}};
        valid_stage1 <= 1'b0;
        up_down_reg <= 1'b0;
    end else begin
        if (load) begin
            cnt_stage1 <= preset;
            valid_stage1 <= 1'b1;
            up_down_reg <= up_down;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
end

// Stage 2: Shift operation - split into two parts
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_stage2 <= {N{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        if (valid_stage1) begin
            // First part of shift operation
            if (up_down_reg) begin
                cnt_stage2 <= {cnt_stage1[N-2:0], 1'b0}; // Prepare for right shift
            end else begin
                cnt_stage2 <= {1'b0, cnt_stage1[N-1:1]}; // Prepare for left shift
            end
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
end

// Stage 3: Complete shift operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_stage3 <= {N{1'b0}};
        valid_stage3 <= 1'b0;
    end else begin
        if (valid_stage2) begin
            // Complete the shift operation
            if (up_down_reg) begin
                cnt_stage3 <= {cnt_stage2[N-1:1], cnt_stage1[N-1]}; // Complete right shift
            end else begin
                cnt_stage3 <= {cnt_stage1[0], cnt_stage2[N-2:0]}; // Complete left shift
            end
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
end

// Stage 4: Output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= {N{1'b0}};
        valid_out <= 1'b0;
    end else begin
        if (valid_stage3) begin
            cnt <= cnt_stage3;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

endmodule