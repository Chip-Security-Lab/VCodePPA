//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Top module: Debounce with synchronized input for multiple interrupts
///////////////////////////////////////////////////////////////////////////////
module debounce_ismu #(
    parameter CNT_WIDTH = 4
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] raw_intr,
    output wire [7:0] stable_intr
);

    // Synchronized interrupt signals
    wire [7:0] synced_intr;
    
    // Signal for detecting input changes
    wire [7:0] change_detected;
    
    // Counter values and counter max flags
    wire [CNT_WIDTH-1:0] counters[0:7];
    wire [7:0] counter_max;

    // Input synchronizer instance
    intr_synchronizer sync_inst (
        .clk        (clk),
        .rst        (rst),
        .raw_intr   (raw_intr),
        .synced_intr(synced_intr)
    );

    // Change detector instance
    change_detector detect_inst (
        .clk            (clk),
        .rst            (rst),
        .synced_intr    (synced_intr),
        .change_detected(change_detected)
    );

    // Counter array instance
    counter_array #(
        .CNT_WIDTH(CNT_WIDTH)
    ) counter_inst (
        .clk            (clk),
        .rst            (rst),
        .change_detected(change_detected),
        .counters       (counters),
        .counter_max    (counter_max)
    );

    // Output stabilizer instance
    output_stabilizer stable_inst (
        .clk        (clk),
        .rst        (rst),
        .synced_intr(synced_intr),
        .counter_max(counter_max),
        .stable_intr(stable_intr)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Input synchronizer module to prevent metastability
///////////////////////////////////////////////////////////////////////////////
module intr_synchronizer (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] raw_intr,
    output reg  [7:0] synced_intr
);

    reg [7:0] intr_r1;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_r1     <= 8'h0;
            synced_intr <= 8'h0;
        end else begin
            intr_r1     <= raw_intr;
            synced_intr <= intr_r1;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Change detector module to identify input transitions
///////////////////////////////////////////////////////////////////////////////
module change_detector (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] synced_intr,
    output reg  [7:0] change_detected
);

    reg [7:0] intr_prev;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_prev       <= 8'h0;
            change_detected <= 8'h0;
        end else begin
            intr_prev       <= synced_intr;
            change_detected <= intr_prev ^ synced_intr;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Counter array module to track stable time of inputs
///////////////////////////////////////////////////////////////////////////////
module counter_array #(
    parameter CNT_WIDTH = 4
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [7:0]             change_detected,
    output reg  [CNT_WIDTH-1:0]   counters[0:7],
    output wire [7:0]             counter_max
);

    // Define the maximum counter value
    wire [CNT_WIDTH-1:0] max_count = {CNT_WIDTH{1'b1}};
    
    // Generate counter_max flags
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_counter_max
            assign counter_max[i] = (counters[i] == max_count);
        end
    endgenerate
    
    integer j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (j = 0; j < 8; j = j + 1)
                counters[j] <= {CNT_WIDTH{1'b0}};
        end else begin
            for (j = 0; j < 8; j = j + 1) begin
                if (change_detected[j])
                    counters[j] <= {CNT_WIDTH{1'b0}};
                else if (!counter_max[j])
                    counters[j] <= counters[j] + 1'b1;
            end
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Output stabilizer module to produce debounced outputs
///////////////////////////////////////////////////////////////////////////////
module output_stabilizer (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] synced_intr,
    input  wire [7:0] counter_max,
    output reg  [7:0] stable_intr
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stable_intr <= 8'h0;
        end else begin
            integer i;
            for (i = 0; i < 8; i = i + 1) begin
                if (counter_max[i])
                    stable_intr[i] <= synced_intr[i];
            end
        end
    end

endmodule