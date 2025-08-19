//SystemVerilog
module int_ctrl_weighted #(
    parameter N = 4
)(
    input clk, rst,
    input [N*4-1:0] weights,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
    reg [7:0] credit_counter[0:N-1];
    reg [7:0] credit_counter_buffered[0:N-1];
    
    // Buffer registers for loop index to reduce fan-out
    reg [31:0] i_stage1;
    reg [31:0] i_stage2[0:1];
    reg [31:0] i_stage3[0:3];
    
    integer i;
    
    // Reset logic
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                credit_counter[i] <= weights[i*4+:4];
            grant <= 0;
        end
    end
    
    // Buffering credit counter values
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < N; i = i + 1)
                credit_counter_buffered[i] <= credit_counter[i];
        end
    end
    
    // Index buffering to reduce fanout
    always @(posedge clk) begin
        if (!rst) begin
            i_stage1 <= i;
            i_stage2[0] <= i_stage1;
            i_stage2[1] <= i_stage1;
            i_stage3[0] <= i_stage2[0];
            i_stage3[1] <= i_stage2[0];
            i_stage3[2] <= i_stage2[1];
            i_stage3[3] <= i_stage2[1];
        end
    end
    
    // Grant generation logic
    always @(posedge clk) begin
        if (rst) begin
            grant <= 0;
        end else begin
            grant <= 0; // Default state for all grants
            for (i = 0; i < N; i = i + 1) begin
                if (req[i] && (credit_counter_buffered[i] > 0)) begin
                    grant[i] <= 1'b1;
                end
            end
        end
    end
    
    // Credit counter update logic
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < N; i = i + 1) begin
                if (req[i] && (credit_counter_buffered[i] > 0)) begin
                    // Decrement credit when request granted
                    credit_counter[i] <= credit_counter_buffered[i] - 1'b1;
                end else if (!req[i] && credit_counter_buffered[i] < {4'b0, weights[i*4+:4]}) begin
                    // Increment credit when no request and below weight limit
                    credit_counter[i] <= credit_counter_buffered[i] + 1'b1;
                end else begin
                    // Maintain current credit value
                    credit_counter[i] <= credit_counter_buffered[i];
                end
            end
        end
    end
endmodule