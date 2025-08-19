//SystemVerilog
module binary_to_thermo #(
    parameter BIN_WIDTH = 3
)(
    input                         clk,
    input                         rst_n,
    input      [BIN_WIDTH-1:0]    bin_in,
    input                         valid_in,
    output reg [(1<<BIN_WIDTH)-1:0] thermo_out,
    output reg                    valid_out
);

    // Pipeline Stage 1: Register input and valid signal
    reg [BIN_WIDTH-1:0] bin_in_stage1;
    reg                 valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_in_stage1 <= {BIN_WIDTH{1'b0}};
            valid_stage1  <= 1'b0;
        end else begin
            bin_in_stage1 <= bin_in;
            valid_stage1  <= valid_in;
        end
    end

    // Pipeline Stage 2: Generate thermometer code and register output, valid signal
    reg [(1<<BIN_WIDTH)-1:0] thermo_stage2;
    reg                      valid_stage2;
    integer                  idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermo_stage2 <= {(1<<BIN_WIDTH){1'b0}};
            valid_stage2  <= 1'b0;
        end else begin
            for (idx = 0; idx < (1<<BIN_WIDTH); idx = idx + 1) begin
                if (idx < bin_in_stage1) begin
                    thermo_stage2[idx] <= 1'b1;
                end else begin
                    thermo_stage2[idx] <= 1'b0;
                end
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline Stage 3: Register thermometer output and valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermo_out <= {(1<<BIN_WIDTH){1'b0}};
            valid_out  <= 1'b0;
        end else begin
            thermo_out <= thermo_stage2;
            valid_out  <= valid_stage2;
        end
    end

endmodule