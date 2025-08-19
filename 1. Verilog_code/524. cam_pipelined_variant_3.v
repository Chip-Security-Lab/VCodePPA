module cam_pipelined #(parameter WIDTH=8, DEPTH=256)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input data_valid,
    output reg [$clog2(DEPTH)-1:0] match_addr,
    output reg match_valid,
    output reg ready
);

    // Pipeline registers
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [DEPTH-1:0] stage1_hits;
    reg [DEPTH-1:0] stage2_hits;
    reg [$clog2(DEPTH)-1:0] stage2_addr;
    reg stage1_valid;
    reg stage2_valid;
    reg [WIDTH-1:0] stage1_data;
    reg [WIDTH-1:0] stage2_data;
    integer i;

    // Pipeline control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b1;
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            match_valid <= 1'b0;
        end else begin
            ready <= !stage1_valid || !stage2_valid;
            stage1_valid <= data_valid && ready;
            stage2_valid <= stage1_valid;
            match_valid <= stage2_valid;
        end
    end

    // Pipeline stage 1 - Compare and generate hits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_hits <= {DEPTH{1'b0}};
            stage1_data <= {WIDTH{1'b0}};
        end else if (data_valid && ready) begin
            stage1_data <= data_in;
            for(i=0; i<DEPTH; i=i+1) begin
                stage1_hits[i] <= (entries[i] == data_in);
            end
        end
    end

    // Pipeline stage 2 - Priority encoder with balanced logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_hits <= {DEPTH{1'b0}};
            stage2_addr <= {($clog2(DEPTH)){1'b0}};
            stage2_data <= {WIDTH{1'b0}};
        end else if (stage1_valid) begin
            stage2_hits <= stage1_hits;
            stage2_data <= stage1_data;
            
            // Balanced priority encoding
            stage2_addr <= 0;
            for(i=0; i<DEPTH; i=i+1) begin
                if(stage1_hits[i]) begin
                    stage2_addr <= i;
                end
            end
        end
    end

    // Pipeline stage 3 - Final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_addr <= {($clog2(DEPTH)){1'b0}};
        end else if (stage2_valid) begin
            match_addr <= stage2_addr;
        end
    end

endmodule