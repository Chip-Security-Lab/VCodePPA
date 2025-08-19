//SystemVerilog
module grouped_ismu (
    input  logic        clk,
    input  logic        rstn,
    input  logic        req,                 // Request signal
    input  logic [15:0] int_sources,
    input  logic [3:0]  group_mask,
    output logic [3:0]  group_int,
    output logic        ack                  // Acknowledge signal
);

    // Internal signals
    logic [3:0] group0, group1, group2, group3;
    logic req_edge_detected;
    logic processing;

    // Interrupt source grouping
    interrupt_grouper i_interrupt_grouper (
        .int_sources (int_sources),
        .group0      (group0),
        .group1      (group1),
        .group2      (group2),
        .group3      (group3)
    );

    // Request edge detection
    edge_detector i_edge_detector (
        .clk         (clk),
        .rstn        (rstn),
        .req         (req),
        .req_detected(req_edge_detected)
    );

    // Control FSM for processing state and acknowledge
    control_fsm i_control_fsm (
        .clk            (clk),
        .rstn           (rstn),
        .req_detected   (req_edge_detected),
        .processing     (processing),
        .ack            (ack)
    );

    // Interrupt generation based on groups and mask
    interrupt_generator i_interrupt_generator (
        .clk         (clk),
        .rstn        (rstn),
        .processing  (processing),
        .ack         (ack),
        .group0      (group0),
        .group1      (group1),
        .group2      (group2),
        .group3      (group3),
        .group_mask  (group_mask),
        .group_int   (group_int)
    );

endmodule : grouped_ismu

// Interrupt source grouping module
module interrupt_grouper (
    input  logic [15:0] int_sources,
    output logic [3:0]  group0,
    output logic [3:0]  group1,
    output logic [3:0]  group2,
    output logic [3:0]  group3
);

    assign group0 = int_sources[3:0];
    assign group1 = int_sources[7:4];
    assign group2 = int_sources[11:8];
    assign group3 = int_sources[15:12];

endmodule : interrupt_grouper

// Request edge detection module
module edge_detector (
    input  logic clk,
    input  logic rstn,
    input  logic req,
    output logic req_detected
);

    logic req_r;

    // Register the request signal
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            req_r <= 1'b0;
        else
            req_r <= req;
    end

    // Detect rising edge
    assign req_detected = req && !req_r;

endmodule : edge_detector

// Control FSM for processing state and acknowledge signal
module control_fsm (
    input  logic clk,
    input  logic rstn,
    input  logic req_detected,
    output logic processing,
    output logic ack
);

    // Processing state control
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            processing <= 1'b0;
        else if (req_detected && !processing)
            processing <= 1'b1;
        else if (processing && ack)
            processing <= 1'b0;
    end
    
    // Generate acknowledge signal
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            ack <= 1'b0;
        else if (processing && !ack)  // Assert ack after one cycle in processing
            ack <= 1'b1;
        else
            ack <= 1'b0;              // Ack is only high for one cycle
    end

endmodule : control_fsm

// Interrupt generation based on groups and mask
module interrupt_generator (
    input  logic       clk,
    input  logic       rstn,
    input  logic       processing,
    input  logic       ack,
    input  logic [3:0] group0,
    input  logic [3:0] group1,
    input  logic [3:0] group2,
    input  logic [3:0] group3,
    input  logic [3:0] group_mask,
    output logic [3:0] group_int
);

    // Group interrupt generation logic
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            group_int <= 4'h0;
        else if (processing && !ack) begin
            group_int[0] <= ~group_mask[0] & (|group0);
            group_int[1] <= ~group_mask[1] & (|group1);
            group_int[2] <= ~group_mask[2] & (|group2);
            group_int[3] <= ~group_mask[3] & (|group3);
        end
    end

endmodule : interrupt_generator