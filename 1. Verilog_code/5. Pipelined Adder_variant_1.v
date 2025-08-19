module pipelined_adder (
    input clk,
    input rst_n,
    input valid_in,
    output reg ready_in,
    input [3:0] a, b,
    output reg valid_out,
    input ready_out,
    output reg [3:0] sum
);

    // Input stage registers
    reg [3:0] reg_a, reg_b;
    reg reg_valid_in;
    
    // Carry lookahead stage registers
    reg [3:0] reg_propagate;
    reg [3:0] reg_generate;
    reg reg_valid_stage1;
    
    // Carry computation stage registers
    reg [3:0] reg_carry;
    reg reg_valid_stage2;
    
    // Sum computation stage registers
    reg [3:0] reg_sum;
    reg reg_valid_stage3;

    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= 4'b0;
            reg_b <= 4'b0;
            reg_valid_in <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            if (valid_in && ready_in) begin
                reg_a <= a;
                reg_b <= b;
                reg_valid_in <= 1'b1;
                ready_in <= 1'b0;
            end else if (!reg_valid_in || (reg_valid_stage1 && ready_out)) begin
                ready_in <= 1'b1;
            end
        end
    end

    // Carry lookahead stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_propagate <= 4'b0;
            reg_generate <= 4'b0;
            reg_valid_stage1 <= 1'b0;
        end else begin
            if (reg_valid_in) begin
                reg_propagate <= reg_a ^ reg_b;
                reg_generate <= reg_a & reg_b;
                reg_valid_stage1 <= 1'b1;
            end else begin
                reg_valid_stage1 <= 1'b0;
            end
        end
    end

    // Carry computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_carry <= 4'b0;
            reg_valid_stage2 <= 1'b0;
        end else begin
            if (reg_valid_stage1) begin
                reg_carry[0] <= reg_generate[0];
                reg_carry[1] <= reg_generate[1] | (reg_propagate[1] & reg_generate[0]);
                reg_carry[2] <= reg_generate[2] | (reg_propagate[2] & reg_generate[1]) | 
                               (reg_propagate[2] & reg_propagate[1] & reg_generate[0]);
                reg_carry[3] <= reg_generate[3] | (reg_propagate[3] & reg_generate[2]) |
                               (reg_propagate[3] & reg_propagate[2] & reg_generate[1]) |
                               (reg_propagate[3] & reg_propagate[2] & reg_propagate[1] & reg_generate[0]);
                reg_valid_stage2 <= 1'b1;
            end else begin
                reg_valid_stage2 <= 1'b0;
            end
        end
    end

    // Sum computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_sum <= 4'b0;
            reg_valid_stage3 <= 1'b0;
        end else begin
            if (reg_valid_stage2) begin
                reg_sum <= reg_propagate ^ {reg_carry[2:0], 1'b0};
                reg_valid_stage3 <= 1'b1;
            end else begin
                reg_valid_stage3 <= 1'b0;
            end
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 4'b0;
            valid_out <= 1'b0;
        end else begin
            if (reg_valid_stage3) begin
                if (ready_out) begin
                    sum <= reg_sum;
                    valid_out <= 1'b1;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule