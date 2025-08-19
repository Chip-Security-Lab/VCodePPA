//SystemVerilog
module priority_pattern_matcher #(parameter WIDTH = 8, PATTERNS = 4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input valid_in,
    input [WIDTH-1:0] patterns [PATTERNS-1:0],
    output reg [($clog2(PATTERNS))-1:0] match_idx,
    output reg match_found,
    output reg valid_out
);

    // Pipeline stage registers
    reg [WIDTH-1:0] data_pipe [2:0];
    reg valid_pipe [2:0];
    reg [PATTERNS-1:0] match_pipe [1:0];
    reg [($clog2(PATTERNS))-1:0] idx_pipe [1:0];
    reg found_pipe [1:0];

    // Stage 1: Pattern matching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe[0] <= 0;
            valid_pipe[0] <= 1'b0;
            match_pipe[0] <= 0;
        end else begin
            data_pipe[0] <= data_in;
            valid_pipe[0] <= valid_in;
            
            for (int i = 0; i < PATTERNS; i++) begin
                match_pipe[0][i] <= (data_in == patterns[i]);
            end
        end
    end

    // Stage 2: Priority encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe[1] <= 0;
            valid_pipe[1] <= 1'b0;
            match_pipe[1] <= 0;
            idx_pipe[0] <= 0;
            found_pipe[0] <= 1'b0;
        end else begin
            data_pipe[1] <= data_pipe[0];
            valid_pipe[1] <= valid_pipe[0];
            match_pipe[1] <= match_pipe[0];
            
            found_pipe[0] <= 1'b0;
            idx_pipe[0] <= 0;
            
            for (int j = PATTERNS-1; j >= 0; j--) begin
                if (match_pipe[0][j]) begin
                    idx_pipe[0] <= j;
                    found_pipe[0] <= 1'b1;
                end
            end
        end
    end

    // Stage 3: Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe[2] <= 0;
            valid_pipe[2] <= 1'b0;
            idx_pipe[1] <= 0;
            found_pipe[1] <= 1'b0;
            match_idx <= 0;
            match_found <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            data_pipe[2] <= data_pipe[1];
            valid_pipe[2] <= valid_pipe[1];
            idx_pipe[1] <= idx_pipe[0];
            found_pipe[1] <= found_pipe[0];
            
            match_idx <= idx_pipe[1];
            match_found <= found_pipe[1];
            valid_out <= valid_pipe[2];
        end
    end

endmodule