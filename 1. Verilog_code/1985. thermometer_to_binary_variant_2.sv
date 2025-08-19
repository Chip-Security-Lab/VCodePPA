//SystemVerilog
module thermometer_to_binary #(
    parameter THERMO_WIDTH = 7
)(
    input  wire                             clk,
    input  wire                             rst_n,
    input  wire [THERMO_WIDTH-1:0]          thermo_in,
    output reg  [$clog2(THERMO_WIDTH+1)-1:0] binary_out
);

    // Pipeline stage 1: Register input
    reg [THERMO_WIDTH-1:0]                  thermo_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            thermo_in_stage1 <= {THERMO_WIDTH{1'b0}};
        else
            thermo_in_stage1 <= thermo_in;
    end

    // Pipeline stage 2: Count bits
    reg [$clog2(THERMO_WIDTH+1)-1:0]        count_stage2;
    integer                                 i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count_stage2 <= {($clog2(THERMO_WIDTH+1)){1'b0}};
        else begin
            count_stage2 <= {($clog2(THERMO_WIDTH+1)){1'b0}};
            for (i = 0; i < THERMO_WIDTH; i = i + 1) begin
                count_stage2 <= count_stage2 + thermo_in_stage1[i];
            end
        end
    end

    // Pipeline stage 3: Register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_out <= {($clog2(THERMO_WIDTH+1)){1'b0}};
        else
            binary_out <= count_stage2;
    end

endmodule