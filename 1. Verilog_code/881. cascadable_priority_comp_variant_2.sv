//SystemVerilog
module cascadable_priority_comp #(parameter WIDTH = 8)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire cascade_in_valid,
    input wire [$clog2(WIDTH)-1:0] cascade_in_idx,
    output reg cascade_out_valid,
    output reg [$clog2(WIDTH)-1:0] cascade_out_idx
);

    // Pipeline stage 1: Local priority encoding
    reg local_valid_r;
    reg [$clog2(WIDTH)-1:0] local_idx_r;
    
    // Pipeline stage 2: Cascade logic
    reg cascade_valid_r;
    reg [$clog2(WIDTH)-1:0] cascade_idx_r;

    // Stage 1: Local priority encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            local_valid_r <= 1'b0;
            local_idx_r <= 0;
        end else begin
            local_valid_r <= |data_in;
            local_idx_r <= encode_priority(data_in);
        end
    end

    // Stage 2: Cascade logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cascade_valid_r <= 1'b0;
            cascade_idx_r <= 0;
        end else begin
            cascade_valid_r <= local_valid_r || cascade_in_valid;
            cascade_idx_r <= local_valid_r ? local_idx_r : cascade_in_idx;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cascade_out_valid <= 1'b0;
            cascade_out_idx <= 0;
        end else begin
            cascade_out_valid <= cascade_valid_r;
            cascade_out_idx <= cascade_idx_r;
        end
    end

    // Priority encoding function
    function [$clog2(WIDTH)-1:0] encode_priority;
        input [WIDTH-1:0] data;
        integer i;
        begin
            encode_priority = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (data[i]) encode_priority = i[$clog2(WIDTH)-1:0];
        end
    endfunction

endmodule