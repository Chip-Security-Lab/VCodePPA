//SystemVerilog
module shift_thermometer_pipeline #(parameter WIDTH=8) (
    input                   clk,
    input                   rst_n,
    input                   dir_in,
    input                   valid_in,
    output                  ready_out,
    output reg [WIDTH-1:0]  therm_out,
    output                  valid_out
);

// Stage 1: Capture input and compute shift direction
reg                        dir_stage1;
reg                        valid_stage1;
wire [WIDTH-1:0]           therm_stage1;
reg [WIDTH-1:0]            therm_reg_stage1;
reg                        ready_stage1;

// Stage 2: Compute shift result
reg [WIDTH-1:0]            therm_stage2;
reg                        valid_stage2;
reg                        dir_stage2;

// Internal thermometer register to hold running value
reg [WIDTH-1:0]            therm_state;

// Ready/Valid logic
assign ready_out = ready_stage1;
assign valid_out = valid_stage2;

// Stage 1: Input capture and direction decode
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dir_stage1         <= 1'b0;
        valid_stage1       <= 1'b0;
        therm_reg_stage1   <= {WIDTH{1'b0}};
        ready_stage1       <= 1'b1;
        therm_state        <= {1'b1, {(WIDTH-1){1'b0}}};
    end else begin
        if (valid_in && ready_stage1) begin
            dir_stage1       <= dir_in;
            valid_stage1     <= 1'b1;
            therm_reg_stage1 <= therm_state;
            ready_stage1     <= 1'b0;
        end else if (!valid_stage1) begin
            ready_stage1     <= 1'b1;
        end
        // Update thermometer state on valid output
        if (valid_out) begin
            therm_state <= therm_out;
        end
    end
end

assign therm_stage1 = therm_reg_stage1;

// Stage 2: Shift logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        therm_stage2 <= {WIDTH{1'b0}};
        valid_stage2 <= 1'b0;
        dir_stage2   <= 1'b0;
    end else begin
        if (valid_stage1) begin
            dir_stage2   <= dir_stage1;
            valid_stage2 <= 1'b1;
            if (dir_stage1) begin
                therm_stage2 <= (therm_stage1 >> 1) | ({1'b1, {(WIDTH-1){1'b0}}});
            end else begin
                therm_stage2 <= (therm_stage1 << 1) | 1'b1;
            end
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
end

// Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        therm_out <= {WIDTH{1'b0}};
    end else if (valid_stage2) begin
        therm_out <= therm_stage2;
    end
end

endmodule